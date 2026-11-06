import assert from 'node:assert/strict';
import { before, test } from 'node:test';

import {
  arrayValue,
  assertEmulatorEnvironment,
  authRequest,
  booleanValue,
  commit,
  documentWrite,
  emulatorOnlyPassword,
  getDocument,
  integerValue,
  mapValue,
  responseJson,
  signIn,
  stringField,
  stringValue,
  timestampTransform,
} from './emulator_helpers.mjs';
import { seedEmulatorData } from './seed.mjs';

let admin;
let customerOne;
let customerTwo;
let product;
let pickupOrderId;
let deliveryOrderId;

function statusKey(status) {
  return {
    Confirmed: 'confirmed',
    Preparing: 'preparing',
    'Out for Delivery': 'out_for_delivery',
    Delivered: 'delivered',
  }[status];
}

function statusTransitionWrites(orderId, status, adminId) {
  const key = statusKey(status);
  const orderTransforms = [timestampTransform('statusUpdatedAt')];
  if (status === 'Confirmed') {
    orderTransforms.push(timestampTransform('confirmedAt'));
  }
  return [
    documentWrite(
      `orders/${orderId}`,
      { orderStatus: stringValue(status) },
      { mask: ['orderStatus'], transforms: orderTransforms },
    ),
    documentWrite(
      `orders/${orderId}/statusHistory/${key}`,
      {
        status: stringValue(status),
        changedBy: stringValue(adminId),
      },
      { transforms: [timestampTransform('changedAt')] },
    ),
    documentWrite(
      `adminActions/status-${orderId}-${key}`,
      {
        adminId: stringValue(adminId),
        action: stringValue('order_status_changed'),
        targetId: stringValue(orderId),
        status: stringValue(status),
      },
      { transforms: [timestampTransform('createdAt')] },
    ),
  ];
}

async function createOrder(token, customerId, orderId, deliveryType) {
  const delivery = deliveryType === 'delivery';
  const quantity = 2;
  const unitPrice = 50;
  const subtotal = quantity * unitPrice;
  const deliveryFee = delivery ? 30 : 0;
  const response = await commit(token, [
    documentWrite(
      `orders/${orderId}`,
      {
        orderNumber: stringValue(orderId),
        customerId: stringValue(customerId),
        items: arrayValue([
          mapValue({
            productId: stringValue(product.id),
            productName: stringValue(product.name),
            unitPrice: integerValue(unitPrice),
            quantity: integerValue(quantity),
            lineTotal: integerValue(subtotal),
          }),
        ]),
        deliveryType: stringValue(deliveryType),
        deliveryAddress: delivery
          ? stringValue('12 Emulator Street')
          : { nullValue: null },
        preferredDate: delivery
          ? stringValue('2030-01-01')
          : { nullValue: null },
        preferredTime: delivery
          ? stringValue('10:00 AM')
          : { nullValue: null },
        subtotal: integerValue(subtotal),
        deliveryFee: integerValue(deliveryFee),
        totalAmount: integerValue(subtotal + deliveryFee),
        paymentMethod: stringValue(
          delivery ? 'Cash on Delivery' : 'Cash on Pickup',
        ),
        paymentStatus: stringValue('Unpaid'),
        orderStatus: stringValue('Pending'),
      },
      { transforms: [timestampTransform('createdAt')] },
    ),
  ]);
  assert.equal(
    response.ok,
    true,
    `Order creation failed (${response.status}): ${await response.text()}`,
  );
}

async function walkOrder(orderId, statuses) {
  for (const status of statuses) {
    const response = await commit(
      admin.idToken,
      statusTransitionWrites(orderId, status, admin.localId),
    );
    assert.equal(
      response.ok,
      true,
      `${status} transition failed (${response.status}): ${await response.text()}`,
    );
    const orderResponse = await getDocument(
      admin.idToken,
      `orders/${orderId}`,
    );
    assert.equal(orderResponse.status, 200);
    assert.equal(
      stringField(await responseJson(orderResponse), 'orderStatus'),
      status,
    );
  }
}

before(async () => {
  assertEmulatorEnvironment();
  const fixtures = await seedEmulatorData();
  const adminFixture = fixtures.users.find((user) => user.key === 'admin');
  const customerOneFixture = fixtures.users.find(
    (user) => user.key === 'customerOne',
  );
  const customerTwoFixture = fixtures.users.find(
    (user) => user.key === 'customerTwo',
  );
  product = fixtures.products[0];
  admin = await signIn(adminFixture.email);
  customerOne = await signIn(customerOneFixture.email);
  customerTwo = await signIn(customerTwoFixture.email);
  pickupOrderId = `AQ-EMULATOR-${Date.now()}-PICKUP`;
  deliveryOrderId = `AQ-EMULATOR-${Date.now()}-DELIVERY`;
});

test('registers a customer and signs in through the Auth emulator', async () => {
  const email = `registered-${Date.now()}@aquaqueue.test`;
  const signup = await authRequest('signup', email, emulatorOnlyPassword);
  const signupBody = await signup.text();
  assert.equal(signup.ok, true, signupBody);
  const created = JSON.parse(signupBody);
  const profileWrite = await commit(created.idToken, [
    documentWrite(
      `users/${created.localId}`,
      {
        fullName: stringValue('New Emulator Customer'),
        email: stringValue(email),
        phoneNumber: stringValue('09171111111'),
        address: stringValue('New Emulator Address'),
        role: stringValue('customer'),
      },
      { transforms: [timestampTransform('createdAt')] },
    ),
  ]);
  assert.equal(profileWrite.ok, true, await profileWrite.text());

  const login = await signIn(email);
  const ownProfile = await getDocument(
    login.idToken,
    `users/${created.localId}`,
  );
  assert.equal(ownProfile.status, 200);
  const profile = await responseJson(ownProfile);
  assert.equal(stringField(profile, 'role'), 'customer');
  assert.equal(stringField(profile, 'email'), email);
});

test('seeded users can log in and customers have distinct identities', () => {
  assert.notEqual(customerOne.localId, customerTwo.localId);
  assert.notEqual(admin.localId, customerOne.localId);
});

test('customer places a pickup order and cannot read another customer order', async () => {
  await createOrder(
    customerOne.idToken,
    customerOne.localId,
    pickupOrderId,
    'pickup',
  );
  const ownerRead = await getDocument(
    customerOne.idToken,
    `orders/${pickupOrderId}`,
  );
  assert.equal(ownerRead.status, 200);
  const otherRead = await getDocument(
    customerTwo.idToken,
    `orders/${pickupOrderId}`,
  );
  assert.equal(otherRead.status, 403);
});

test('customer places a delivery order and admins can read it', async () => {
  await createOrder(
    customerOne.idToken,
    customerOne.localId,
    deliveryOrderId,
    'delivery',
  );
  const adminRead = await getDocument(
    admin.idToken,
    `orders/${deliveryOrderId}`,
  );
  assert.equal(adminRead.status, 200);
});

test('admins can perform the pickup lifecycle with atomic history and audit', async () => {
  await walkOrder(pickupOrderId, ['Confirmed', 'Preparing', 'Delivered']);
  const history = await getDocument(
    admin.idToken,
    `orders/${pickupOrderId}/statusHistory/delivered`,
  );
  assert.equal(history.status, 200);
  const action = await getDocument(
    admin.idToken,
    `adminActions/status-${pickupOrderId}-delivered`,
  );
  assert.equal(action.status, 200);
});

test('admins can perform the delivery lifecycle with atomic history and audit', async () => {
  await walkOrder(deliveryOrderId, [
    'Confirmed',
    'Preparing',
    'Out for Delivery',
    'Delivered',
  ]);
  const history = await getDocument(
    admin.idToken,
    `orders/${deliveryOrderId}/statusHistory/out_for_delivery`,
  );
  assert.equal(history.status, 200);
});

test('customers cannot change order status or write catalog products', async () => {
  const statusResponse = await commit(customerOne.idToken, [
    documentWrite(
      `orders/${deliveryOrderId}`,
      { orderStatus: stringValue('Cancelled') },
      { mask: ['orderStatus'] },
    ),
  ]);
  assert.equal(statusResponse.status, 403);

  const productResponse = await commit(customerOne.idToken, [
    documentWrite(
      `products/customer-forbidden-${Date.now()}`,
      {
        name: stringValue('Customer Attempt'),
        description: stringValue('Not allowed'),
        price: integerValue(5),
        category: stringValue('purified'),
        available: booleanValue(true),
      },
      {
        transforms: [
          timestampTransform('createdAt'),
          timestampTransform('updatedAt'),
        ],
      },
    ),
  ]);
  assert.equal(productResponse.status, 403);
});

test('admin can write a product and read customer profiles', async () => {
  const productId = `emulator-admin-product-${Date.now()}`;
  const createProduct = await commit(admin.idToken, [
    documentWrite(
      `products/${productId}`,
      {
        name: stringValue('Admin Emulator Product'),
        description: stringValue('Created by the emulator admin test.'),
        price: integerValue(42),
        category: stringValue('purified'),
        available: booleanValue(true),
      },
      {
        transforms: [
          timestampTransform('createdAt'),
          timestampTransform('updatedAt'),
        ],
      },
    ),
  ]);
  assert.equal(createProduct.ok, true, await createProduct.text());

  const profile = await getDocument(
    admin.idToken,
    `users/${customerTwo.localId}`,
  );
  assert.equal(profile.status, 200);
});

test('customers cannot change their own role or read another profile', async () => {
  const roleChange = await commit(customerOne.idToken, [
    documentWrite(
      `users/${customerOne.localId}`,
      { role: stringValue('admin') },
      { mask: ['role'] },
    ),
  ]);
  assert.equal(roleChange.status, 403);

  const otherProfile = await getDocument(
    customerOne.idToken,
    `users/${customerTwo.localId}`,
  );
  assert.equal(otherProfile.status, 403);
});
