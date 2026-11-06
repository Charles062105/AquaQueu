import assert from 'node:assert/strict';
import { before, test } from 'node:test';

const projectId = process.env.FIREBASE_PROJECT_ID ?? 'demo-aquaqueue';
const authUrl =
  process.env.FIREBASE_AUTH_EMULATOR_URL ??
  'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const documentsUrl =
  process.env.FIRESTORE_EMULATOR_URL ??
  `http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents`;
const resourcePrefix =
  `projects/${projectId}/databases/(default)/documents`;
const runId = `${Date.now()}`;

let customer;
let otherCustomer;
let admin;
let productId;
let otherOrderId;
let ownedOrderId;

const stringValue = (value) => ({ stringValue: value });
const integerValue = (value) => ({ integerValue: String(value) });
const booleanValue = (value) => ({ booleanValue: value });
const geoPointValue = (latitude, longitude) => ({
  geoPointValue: { latitude, longitude },
});
const timestampValue = (value = new Date().toISOString()) => ({
  timestampValue: value,
});
const nullValue = () => ({ nullValue: null });
const mapValue = (fields) => ({ mapValue: { fields } });
const arrayValue = (values) => ({ arrayValue: { values } });

async function assertOk(response) {
  if (!response.ok) {
    throw new Error(`${response.status}: ${await response.text()}`);
  }
}

async function createAuthUser(name) {
  const response = await fetch(
    `${authUrl}/accounts:signUp?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: `${name}-${runId}@example.com`,
        password: 'LocalTest123!',
        returnSecureToken: true,
      }),
    },
  );
  await assertOk(response);
  const result = await response.json();
  return { uid: result.localId, email: result.email, token: result.idToken };
}

async function commit(token, writes) {
  return fetch(`${documentsUrl}:commit`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ writes }),
  });
}

function documentWrite(path, fields, { mask, transforms } = {}) {
  const write = {
    update: { name: `${resourcePrefix}/${path}`, fields },
  };
  if (mask) write.updateMask = { fieldPaths: mask };
  if (transforms) write.updateTransforms = transforms;
  return write;
}

function orderWrite(orderId, customerId, overrides = {}) {
  const fields = {
    orderNumber: stringValue(orderId),
    customerId: stringValue(customerId),
    items: arrayValue([
      mapValue({
        productId: stringValue(productId),
        productName: stringValue('Rules Test Water'),
        unitPrice: integerValue(50),
        quantity: integerValue(2),
        lineTotal: integerValue(100),
      }),
    ]),
    deliveryType: stringValue('pickup'),
    deliveryAddress: nullValue(),
    preferredDate: nullValue(),
    preferredTime: nullValue(),
    subtotal: integerValue(100),
    deliveryFee: integerValue(0),
    totalAmount: integerValue(100),
    paymentMethod: stringValue('Cash on Pickup'),
    paymentStatus: stringValue('Unpaid'),
    orderStatus: stringValue('Pending'),
    ...overrides,
  };
  return documentWrite(`orders/${orderId}`, fields, {
    transforms: [
      { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
    ],
  });
}

function productWrite(productId, overrides = {}, { mask, transforms } = {}) {
  const fields = {
    name: stringValue('Rules Test Water'),
    description: stringValue('Rules test product'),
    price: integerValue(50),
    category: stringValue('purified'),
    available: booleanValue(true),
    imageUrl: nullValue(),
    ...overrides,
  };
  return documentWrite(`products/${productId}`, fields, { mask, transforms });
}

function statusKey(status) {
  return {
    Pending: 'pending',
    Confirmed: 'confirmed',
    Preparing: 'preparing',
    'Out for Delivery': 'out_for_delivery',
    Delivered: 'delivered',
    Cancelled: 'cancelled',
  }[status];
}

function adminActionWrite(actionId, action, targetId, status) {
  const fields = {
    adminId: stringValue(admin.uid),
    action: stringValue(action),
    targetId: stringValue(targetId),
  };
  if (status) fields.status = stringValue(status);
  return documentWrite(
    `adminActions/${actionId}`,
    fields,
    {
      transforms: [
        { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
      ],
    },
  );
}

function statusTransitionWrites(orderId, status, changedBy = admin.uid) {
  const key = statusKey(status);
  const transforms = [
    { fieldPath: 'statusUpdatedAt', setToServerValue: 'REQUEST_TIME' },
  ];
  if (status === 'Confirmed') {
    transforms.push({
      fieldPath: 'confirmedAt',
      setToServerValue: 'REQUEST_TIME',
    });
  }
  return [
    documentWrite(
      `orders/${orderId}`,
      { orderStatus: stringValue(status) },
      { mask: ['orderStatus'], transforms },
    ),
    documentWrite(
      `orders/${orderId}/statusHistory/${key}`,
      {
        status: stringValue(status),
        changedBy: stringValue(changedBy),
      },
      {
        transforms: [
          { fieldPath: 'changedAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ),
    adminActionWrite(
      `status-${orderId}-${key}`,
      'order_status_changed',
      orderId,
      status,
    ),
  ];
}

async function seedOrder(orderId, status, deliveryType) {
  const isDelivery = deliveryType === 'delivery';
  const response = await commit('owner', [
    orderWrite(orderId, customer.uid, {
      orderStatus: stringValue(status),
      deliveryType: stringValue(deliveryType),
      deliveryAddress: isDelivery
        ? stringValue('12 Emulator Street')
        : nullValue(),
      preferredDate: isDelivery ? stringValue('2030-01-01') : nullValue(),
      preferredTime: isDelivery ? stringValue('10:00 AM') : nullValue(),
      deliveryFee: integerValue(isDelivery ? 30 : 0),
      totalAmount: integerValue(isDelivery ? 130 : 100),
      paymentMethod: stringValue(
        isDelivery ? 'Cash on Delivery' : 'Cash on Pickup',
      ),
    }),
  ]);
  await assertOk(response);
}

async function commitUnauthenticated(writes) {
  return fetch(`${documentsUrl}:commit`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ writes }),
  });
}

async function createOrder(token, orderId, customerId, overrides = {}) {
  return commit(token, [orderWrite(orderId, customerId, overrides)]);
}

async function getDocument(token, path) {
  return fetch(`${documentsUrl}/${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
}

before(async () => {
  customer = await createAuthUser('customer');
  otherCustomer = await createAuthUser('other-customer');
  admin = await createAuthUser('admin');
  productId = `rules-product-${runId}`;
  otherOrderId = `AQ-${runId}-OTHER`;
  ownedOrderId = `AQ-${runId}-OWNED`;

  for (const user of [customer, otherCustomer, admin]) {
    const response = await commit('owner', [
      documentWrite(`users/${user.uid}`, {
        fullName: stringValue('Rules Test User'),
        email: stringValue(user.email),
        phoneNumber: stringValue('09171234567'),
        address: stringValue('12 Emulator Street'),
        role: stringValue('customer'),
        createdAt: timestampValue(),
      }),
    ]);
    await assertOk(response);
  }

  await assertOk(
    await commit('owner', [
      documentWrite(
        `users/${admin.uid}`,
        { role: stringValue('admin') },
        { mask: ['role'] },
      ),
      documentWrite(`products/${productId}`, {
        name: stringValue('Rules Test Water'),
        description: stringValue('Rules test product'),
        price: integerValue(50),
        category: stringValue('purified'),
        available: booleanValue(true),
        imageUrl: nullValue(),
        createdAt: timestampValue(),
        updatedAt: timestampValue(),
      }),
    ]),
  );

  await assertOk(
    await commit('owner', [
      orderWrite(otherOrderId, otherCustomer.uid),
      orderWrite(ownedOrderId, customer.uid),
    ]),
  );
});

test('admin can read all user profiles', async () => {
  const response = await getDocument(
    admin.token,
    `users/${otherCustomer.uid}`,
  );
  assert.equal(response.status, 200);
});

test('customer reads own profile', async () => {
  const response = await getDocument(customer.token, `users/${customer.uid}`);
  assert.equal(response.status, 200);
});

test('customer cannot read another profile', async () => {
  const response = await getDocument(
    customer.token,
    `users/${otherCustomer.uid}`,
  );
  assert.equal(response.status, 403);
});

test('customer cannot change own role', async () => {
  const response = await commit(customer.token, [
    documentWrite(
      `users/${customer.uid}`,
      { role: stringValue('admin') },
      { mask: ['role'] },
    ),
  ]);
  assert.equal(response.status, 403);
});

test('customer cannot write a product', async () => {
  const response = await commit(customer.token, [
    productWrite(`customer-write-${runId}`),
  ]);
  assert.equal(response.status, 403);
});

test('admin can write a product', async () => {
  const response = await commit(admin.token, [
    productWrite(
      `admin-write-${runId}`,
      {
        name: stringValue('Administrator Product'),
        price: integerValue(55),
        imageUrl: stringValue('https://example.com/water.jpg'),
      },
      {
        transforms: [
          { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
          { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ),
  ]);
  await assertOk(response);
});

test('admin can edit and disable a product without deleting it', async () => {
  const disableId = `disable-product-${runId}`;
  await assertOk(
    await commit(admin.token, [
      productWrite(
        disableId,
        {},
        {
          transforms: [
            { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
            { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
          ],
        },
      ),
    ]),
  );
  const response = await commit(admin.token, [
    productWrite(
      disableId,
      {
        name: stringValue('Updated Rules Test Water'),
        available: booleanValue(false),
      },
      {
        mask: ['name', 'available'],
        transforms: [
          { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ),
  ]);
  await assertOk(response);
});

test('admin product create rejects invalid fields', async () => {
  const response = await commit(admin.token, [
    productWrite(
      `invalid-product-${runId}`,
      {
        price: integerValue(0),
        imageUrl: stringValue('not-a-url'),
      },
      {
        transforms: [
          { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
          { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ),
  ]);
  assert.equal(response.status, 403);
});

test('customer cannot update product availability', async () => {
  const response = await commit(customer.token, [
    productWrite(
      productId,
      { available: booleanValue(false) },
      {
        mask: ['available'],
        transforms: [
          { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ),
  ]);
  assert.equal(response.status, 403);
});

test('product deletion is denied to admins', async () => {
  const response = await fetch(`${documentsUrl}/products/${productId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${admin.token}` },
  });
  assert.equal(response.status, 403);
});

test('customer can read another signed-in user product', async () => {
  const response = await getDocument(
    customer.token,
    `products/${productId}`,
  );
  assert.equal(response.status, 200);
});

test('customer can create a valid pickup order', async () => {
  const orderId = `AQ-${runId}-PICKUP`;
  await assertOk(await createOrder(customer.token, orderId, customer.uid));
});

test('customer can create a valid delivery order', async () => {
  const orderId = `AQ-${runId}-DELIVERY`;
  await assertOk(
    await createOrder(customer.token, orderId, customer.uid, {
      deliveryType: stringValue('delivery'),
      deliveryAddress: stringValue('12 Emulator Street'),
      preferredDate: stringValue('2030-01-01'),
      preferredTime: stringValue('10:00 AM'),
      deliveryFee: integerValue(30),
      totalAmount: integerValue(130),
      paymentMethod: stringValue('Cash on Delivery'),
    }),
  );
});

test('customer can create a delivery order with a valid location pin', async () => {
  const orderId = `AQ-${runId}-DELIVERY-LOCATION`;
  await assertOk(
    await createOrder(customer.token, orderId, customer.uid, {
      deliveryType: stringValue('delivery'),
      deliveryAddress: stringValue('12 Emulator Street'),
      preferredDate: stringValue('2030-01-01'),
      preferredTime: stringValue('10:00 AM'),
      deliveryFee: integerValue(30),
      totalAmount: integerValue(130),
      paymentMethod: stringValue('Cash on Delivery'),
      deliveryLocation: geoPointValue(6.9214, 122.079),
    }),
  );
});

test('pickup order with a delivery location is denied', async () => {
  const response = await createOrder(
    customer.token,
    `AQ-${runId}-PICKUP-LOCATION`,
    customer.uid,
    { deliveryLocation: geoPointValue(6.9214, 122.079) },
  );
  assert.equal(response.status, 403);
});

test('delivery order with wrong deliveryLocation type is denied', async () => {
  const response = await createOrder(
    customer.token,
    `AQ-${runId}-LOCATION-TYPE`,
    customer.uid,
    {
      deliveryType: stringValue('delivery'),
      deliveryAddress: stringValue('12 Emulator Street'),
      preferredDate: stringValue('2030-01-01'),
      preferredTime: stringValue('10:00 AM'),
      deliveryFee: integerValue(30),
      totalAmount: integerValue(130),
      paymentMethod: stringValue('Cash on Delivery'),
      deliveryLocation: stringValue('6.9214,122.079'),
    },
  );
  assert.equal(response.status, 403);
});

test('delivery order with out-of-range coordinates is denied', async () => {
  const response = await createOrder(
    customer.token,
    `AQ-${runId}-LOCATION-RANGE`,
    customer.uid,
    {
      deliveryType: stringValue('delivery'),
      deliveryAddress: stringValue('12 Emulator Street'),
      preferredDate: stringValue('2030-01-01'),
      preferredTime: stringValue('10:00 AM'),
      deliveryFee: integerValue(30),
      totalAmount: integerValue(130),
      paymentMethod: stringValue('Cash on Delivery'),
      deliveryLocation: geoPointValue(91, 122.079),
    },
  );
  // Firestore rejects out-of-range GeoPoints before evaluating security rules.
  assert.equal(response.status, 400);
});

test('admin cannot change a delivery location after order creation', async () => {
  const orderId = `AQ-${runId}-LOCATION-IMMUTABLE`;
  await assertOk(
    await createOrder(customer.token, orderId, customer.uid, {
      deliveryType: stringValue('delivery'),
      deliveryAddress: stringValue('12 Emulator Street'),
      preferredDate: stringValue('2030-01-01'),
      preferredTime: stringValue('10:00 AM'),
      deliveryFee: integerValue(30),
      totalAmount: integerValue(130),
      paymentMethod: stringValue('Cash on Delivery'),
      deliveryLocation: geoPointValue(6.9214, 122.079),
    }),
  );
  const response = await commit(admin.token, [
    documentWrite(
      `orders/${orderId}`,
      { deliveryLocation: geoPointValue(7, 123) },
      { mask: ['deliveryLocation'] },
    ),
  ]);
  assert.equal(response.status, 403);
});

test('pickup order with a delivery fee is denied', async () => {
  const orderId = `AQ-${runId}-PICKUP-FEE`;
  const response = await createOrder(customer.token, orderId, customer.uid, {
    deliveryFee: integerValue(30),
    totalAmount: integerValue(130),
  });
  assert.equal(response.status, 403);
});

test('order with a wrong total is denied', async () => {
  const orderId = `AQ-${runId}-WRONG-TOTAL`;
  const response = await createOrder(customer.token, orderId, customer.uid, {
    totalAmount: integerValue(101),
  });
  assert.equal(response.status, 403);
});

test('customer cannot create an order for another customerId', async () => {
  const orderId = `AQ-${runId}-FOREIGN-OWNER`;
  const response = await createOrder(
    customer.token,
    orderId,
    otherCustomer.uid,
  );
  assert.equal(response.status, 403);
});

test('order with a status other than Pending is denied', async () => {
  const orderId = `AQ-${runId}-STATUS`;
  const response = await createOrder(customer.token, orderId, customer.uid, {
    orderStatus: stringValue('Confirmed'),
  });
  assert.equal(response.status, 403);
});

test('order with payment status other than Unpaid is denied', async () => {
  const orderId = `AQ-${runId}-PAYMENT`;
  const response = await createOrder(customer.token, orderId, customer.uid, {
    paymentStatus: stringValue('Paid'),
  });
  assert.equal(response.status, 403);
});

test('customer cannot read another customer order', async () => {
  const response = await getDocument(
    customer.token,
    `orders/${otherOrderId}`,
  );
  assert.equal(response.status, 403);
});

test('admin can read all customer orders', async () => {
  const response = await getDocument(admin.token, `orders/${otherOrderId}`);
  assert.equal(response.status, 200);
});

const allowedTransitions = [
  ['Pending', 'Confirmed', 'pickup'],
  ['Pending', 'Cancelled', 'pickup'],
  ['Confirmed', 'Preparing', 'pickup'],
  ['Confirmed', 'Cancelled', 'delivery'],
  ['Preparing', 'Out for Delivery', 'delivery'],
  ['Preparing', 'Delivered', 'pickup'],
  ['Preparing', 'Cancelled', 'pickup'],
  ['Out for Delivery', 'Delivered', 'delivery'],
  ['Out for Delivery', 'Cancelled', 'delivery'],
];

for (const [fromStatus, toStatus, deliveryType] of allowedTransitions) {
  test(`admin may transition ${fromStatus} to ${toStatus} (${deliveryType})`, async () => {
    const orderId = `AQ-${runId}-ALLOW-${statusKey(fromStatus)}-${statusKey(toStatus)}-${deliveryType}`;
    await seedOrder(orderId, fromStatus, deliveryType);
    await assertOk(
      await commit(admin.token, statusTransitionWrites(orderId, toStatus)),
    );
    const historyResponse = await getDocument(
      customer.token,
      `orders/${orderId}/statusHistory/${statusKey(toStatus)}`,
    );
    const historyListResponse = await getDocument(
      customer.token,
      `orders/${orderId}/statusHistory`,
    );
    const actionResponse = await getDocument(
      admin.token,
      `adminActions/status-${orderId}-${statusKey(toStatus)}`,
    );
    assert.equal(historyResponse.status, 200);
    assert.equal(historyListResponse.status, 200);
    assert.equal(actionResponse.status, 200);
  });
}

test('admin status update without history and audit records is denied', async () => {
  const orderId = `AQ-${runId}-NO-HISTORY`;
  await seedOrder(orderId, 'Pending', 'pickup');
  const response = await commit(admin.token, [
    documentWrite(
      `orders/${orderId}`,
      { orderStatus: stringValue('Confirmed') },
      {
        mask: ['orderStatus'],
        transforms: [
          { fieldPath: 'statusUpdatedAt', setToServerValue: 'REQUEST_TIME' },
          { fieldPath: 'confirmedAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ),
  ]);
  assert.equal(response.status, 403);
});

test('customers cannot read another customer order status history', async () => {
  await assertOk(
    await commit(
      admin.token,
      statusTransitionWrites(otherOrderId, 'Confirmed'),
    ),
  );
  const response = await getDocument(
    customer.token,
    `orders/${otherOrderId}/statusHistory/confirmed`,
  );
  assert.equal(response.status, 403);
});

test('admin can confirm payment and create an audit record', async () => {
  const actionId = `confirm-payment-${runId}`;
  const response = await commit(admin.token, [
    documentWrite(
      `orders/${ownedOrderId}`,
      { paymentStatus: stringValue('Paid') },
      {
        mask: ['paymentStatus'],
        transforms: [{ fieldPath: 'paidAt', setToServerValue: 'REQUEST_TIME' }],
      },
    ),
    adminActionWrite(actionId, 'payment_confirmed', ownedOrderId),
  ]);
  await assertOk(response);
});

test('customer cannot confirm an order or payment', async () => {
  const orderResponse = await commit(customer.token, [
    documentWrite(
      `orders/${otherOrderId}`,
      { orderStatus: stringValue('Confirmed') },
      {
        mask: ['orderStatus'],
        transforms: [
          { fieldPath: 'confirmedAt', setToServerValue: 'REQUEST_TIME' },
        ],
      },
    ),
  ]);
  const paymentResponse = await commit(customer.token, [
    documentWrite(
      `orders/${otherOrderId}`,
      { paymentStatus: stringValue('Paid') },
      {
        mask: ['paymentStatus'],
        transforms: [{ fieldPath: 'paidAt', setToServerValue: 'REQUEST_TIME' }],
      },
    ),
  ]);
  assert.equal(orderResponse.status, 403);
  assert.equal(paymentResponse.status, 403);
});

test('admin cannot alter order totals or customer data', async () => {
  const totalResponse = await commit(admin.token, [
    documentWrite(
      `orders/${otherOrderId}`,
      { totalAmount: integerValue(999) },
      { mask: ['totalAmount'] },
    ),
  ]);
  const customerResponse = await commit(admin.token, [
    documentWrite(
      `orders/${otherOrderId}`,
      { customerId: stringValue(admin.uid) },
      { mask: ['customerId'] },
    ),
  ]);
  assert.equal(totalResponse.status, 403);
  assert.equal(customerResponse.status, 403);
});

test('admin cannot edit another user profile', async () => {
  const response = await commit(admin.token, [
    documentWrite(
      `users/${otherCustomer.uid}`,
      { fullName: stringValue('Changed by admin') },
      { mask: ['fullName'] },
    ),
  ]);
  assert.equal(response.status, 403);
});

async function assertStatusDenied(orderId, fromStatus, toStatus, deliveryType, token = admin.token) {
  await seedOrder(orderId, fromStatus, deliveryType);
  const response = await commit(
    token,
    statusTransitionWrites(orderId, toStatus),
  );
  assert.equal(response.status, 403);
}

test('status changes cannot skip steps', async () => {
  await assertStatusDenied(
    `AQ-${runId}-SKIP`,
    'Pending',
    'Preparing',
    'delivery',
  );
});

test('status changes cannot move backward', async () => {
  await assertStatusDenied(
    `AQ-${runId}-BACKWARD`,
    'Confirmed',
    'Pending',
    'pickup',
  );
});

test('cancelled orders cannot become delivered', async () => {
  await assertStatusDenied(
    `AQ-${runId}-CANCELLED-DELIVERED`,
    'Cancelled',
    'Delivered',
    'delivery',
  );
});

test('delivered orders are final', async () => {
  await assertStatusDenied(
    `AQ-${runId}-DELIVERED-FINAL`,
    'Delivered',
    'Cancelled',
    'pickup',
  );
});

test('cancelled orders are final', async () => {
  await assertStatusDenied(
    `AQ-${runId}-CANCELLED-FINAL`,
    'Cancelled',
    'Confirmed',
    'delivery',
  );
});

test('pickup orders cannot use Out for Delivery', async () => {
  await assertStatusDenied(
    `AQ-${runId}-PICKUP-OUT`,
    'Preparing',
    'Out for Delivery',
    'pickup',
  );
});

test('customers cannot change order status', async () => {
  await assertStatusDenied(
    `AQ-${runId}-CUSTOMER-STATUS`,
    'Pending',
    'Confirmed',
    'pickup',
    customer.token,
  );
});

test('unauthenticated clients cannot change order status', async () => {
  const orderId = `AQ-${runId}-UNAUTHENTICATED`;
  await seedOrder(orderId, 'Pending', 'delivery');
  const response = await commitUnauthenticated(
    statusTransitionWrites(orderId, 'Confirmed'),
  );
  assert.equal(response.status, 403);
});

test('status history entries cannot be updated or deleted', async () => {
  const orderId = `AQ-${runId}-IMMUTABLE-HISTORY`;
  await seedOrder(orderId, 'Pending', 'pickup');
  await assertOk(
    await commit(
      admin.token,
      statusTransitionWrites(orderId, 'Confirmed'),
    ),
  );
  const historyPath = `orders/${orderId}/statusHistory/confirmed`;
  const updateResponse = await commit(admin.token, [
    documentWrite(historyPath, { changedBy: stringValue('other-admin') }, {
      mask: ['changedBy'],
    }),
  ]);
  const deleteResponse = await fetch(`${documentsUrl}/${historyPath}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${admin.token}` },
  });
  assert.equal(updateResponse.status, 403);
  assert.equal(deleteResponse.status, 403);
});

test('customer cannot create or read admin actions', async () => {
  const createResponse = await commit(customer.token, [
    adminActionWrite(`customer-action-${runId}`, 'product_edited', productId),
  ]);
  const readResponse = await getDocument(
    customer.token,
    `adminActions/confirm-order-${runId}`,
  );
  assert.equal(createResponse.status, 403);
  assert.equal(readResponse.status, 403);
});

test('admin-created audit actions cannot be updated or deleted', async () => {
  const actionId = `immutable-action-${runId}`;
  await assertOk(
    await commit(admin.token, [
      adminActionWrite(actionId, 'product_edited', productId),
    ]),
  );
  const updateResponse = await commit(admin.token, [
    documentWrite(
      `adminActions/${actionId}`,
      { targetId: stringValue('changed-target') },
      { mask: ['targetId'] },
    ),
  ]);
  const deleteResponse = await fetch(
    `${documentsUrl}/adminActions/${actionId}`,
    {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${admin.token}` },
    },
  );
  assert.equal(updateResponse.status, 403);
  assert.equal(deleteResponse.status, 403);
});

test('customer cannot update an order', async () => {
  const response = await commit(customer.token, [
    documentWrite(
      `orders/${ownedOrderId}`,
      { paymentStatus: stringValue('Paid') },
      { mask: ['paymentStatus'] },
    ),
  ]);
  assert.equal(response.status, 403);
});

test('customer cannot delete an order', async () => {
  const response = await fetch(`${documentsUrl}/orders/${ownedOrderId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${customer.token}` },
  });
  assert.equal(response.status, 403);
});
