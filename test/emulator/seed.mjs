import assert from 'node:assert/strict';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

import {
  assertEmulatorEnvironment,
  commitAsEmulatorOwner,
  documentWrite,
  ensureAuthUser,
  stringValue,
  timestampTransform,
} from './emulator_helpers.mjs';

const userFixtures = [
  {
    key: 'admin',
    email: 'admin@aquaqueue.test',
    fullName: 'AquaQueue Emulator Admin',
    role: 'admin',
  },
  {
    key: 'customerOne',
    email: 'customer.one@aquaqueue.test',
    fullName: 'Emulator Customer One',
    role: 'customer',
  },
  {
    key: 'customerTwo',
    email: 'customer.two@aquaqueue.test',
    fullName: 'Emulator Customer Two',
    role: 'customer',
  },
];

const products = [
  {
    id: 'emulator-purified-5gal',
    name: 'Purified Water - 5 Gallon',
    description: 'Emulator seed catalog item.',
    price: 50,
    category: 'purified',
  },
  {
    id: 'emulator-mineral-5gal',
    name: 'Mineral Water - 5 Gallon',
    description: 'Emulator seed catalog item.',
    price: 75,
    category: 'mineral',
  },
  {
    id: 'emulator-purified-1gal',
    name: 'Purified Water - 1 Gallon',
    description: 'Emulator seed catalog item.',
    price: 20,
    category: 'purified',
  },
];

async function assertSuccessfulWrite(response, label) {
  assert.equal(
    response.ok,
    true,
    `${label} failed (${response.status}): ${await response.text()}`,
  );
}

export async function seedEmulatorData() {
  assertEmulatorEnvironment();
  const users = [];
  for (const fixture of userFixtures) {
    const authUser = await ensureAuthUser(fixture.email);
    users.push({ ...fixture, uid: authUser.localId });
  }

  const userWrites = users.map((user) =>
    documentWrite(
      `users/${user.uid}`,
      {
        fullName: stringValue(user.fullName),
        email: stringValue(user.email),
        phoneNumber: stringValue('09170000000'),
        address: stringValue('Emulator Test Address'),
        role: stringValue(user.role),
      },
      { transforms: [timestampTransform('createdAt')] },
    ),
  );
  await assertSuccessfulWrite(
    await commitAsEmulatorOwner(userWrites),
    'Emulator user fixtures',
  );

  const productWrites = products.map((product) =>
    documentWrite(
      `products/${product.id}`,
      {
        name: stringValue(product.name),
        description: stringValue(product.description),
        price: { integerValue: String(product.price) },
        category: stringValue(product.category),
        available: { booleanValue: true },
        imageUrl: { nullValue: null },
      },
      {
        transforms: [
          timestampTransform('createdAt'),
          timestampTransform('updatedAt'),
        ],
      },
    ),
  );
  await assertSuccessfulWrite(
    await commitAsEmulatorOwner(productWrites),
    'Emulator product fixtures',
  );

  return { users, products };
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  const { users, products: seededProducts } = await seedEmulatorData();
  console.log(
    `Seeded ${users.length} emulator users (1 admin, 2 customers) and ` +
      `${seededProducts.length} emulator products in demo-aquaqueue.`,
  );
}
