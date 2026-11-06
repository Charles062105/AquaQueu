import assert from 'node:assert/strict';

export const projectId = 'demo-aquaqueue';
export const authBaseUrl =
  'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
export const documentsUrl =
  `http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents`;
export const resourcePrefix =
  `projects/${projectId}/databases/(default)/documents`;
export const emulatorOnlyPassword = 'LocalOnly123!';

export function assertEmulatorEnvironment() {
  const configuredProject =
    process.env.FIREBASE_PROJECT_ID ?? process.env.GCLOUD_PROJECT;
  assert.notEqual(
    configuredProject,
    'aquaqueue-af8d3',
    'Emulator tests must never use the production Firebase project.',
  );
  if (configuredProject != null) {
    assert.equal(
      configuredProject,
      projectId,
      'Emulator tests only support the demo-aquaqueue project.',
    );
  }
  assert.equal(new URL(authBaseUrl).hostname, '127.0.0.1');
  assert.equal(new URL(documentsUrl).hostname, '127.0.0.1');
}

export const stringValue = (value) => ({ stringValue: value });
export const integerValue = (value) => ({ integerValue: String(value) });
export const booleanValue = (value) => ({ booleanValue: value });
export const nullValue = () => ({ nullValue: null });
export const arrayValue = (values) => ({ arrayValue: { values } });
export const mapValue = (fields) => ({ mapValue: { fields } });

export function timestampTransform(fieldPath) {
  return { fieldPath, setToServerValue: 'REQUEST_TIME' };
}

export async function authRequest(method, email, password) {
  const endpoint =
    method === 'signup' ? 'accounts:signUp' : 'accounts:signInWithPassword';
  return fetch(`${authBaseUrl}/${endpoint}?key=fake-api-key`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      returnSecureToken: true,
    }),
  });
}

export async function ensureAuthUser(email) {
  let response = await authRequest('signup', email, emulatorOnlyPassword);
  if (!response.ok) {
    const body = await response.json();
    assert.equal(body.error?.message, 'EMAIL_EXISTS');
    response = await authRequest('signin', email, emulatorOnlyPassword);
  }
  const body = await response.text();
  assert.equal(response.ok, true, body);
  return JSON.parse(body);
}

export async function signIn(email, password = emulatorOnlyPassword) {
  const response = await authRequest('signin', email, password);
  const body = await response.text();
  assert.equal(response.ok, true, body);
  return JSON.parse(body);
}

export async function commit(token, writes) {
  return fetch(`${documentsUrl}:commit`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ writes }),
  });
}

export async function commitAsEmulatorOwner(writes) {
  // The emulator's owner token bypasses rules only for local fixture setup.
  return fetch(`${documentsUrl}:commit`, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer owner',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ writes }),
  });
}

export function documentWrite(path, fields, { mask, transforms } = {}) {
  const write = {
    update: { name: `${resourcePrefix}/${path}`, fields },
  };
  if (mask) write.updateMask = { fieldPaths: mask };
  if (transforms) write.updateTransforms = transforms;
  return write;
}

export async function getDocument(token, path) {
  return fetch(`${documentsUrl}/${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
}

export async function responseJson(response) {
  const body = await response.text();
  return body.length === 0 ? null : JSON.parse(body);
}

export function stringField(document, name) {
  return document.fields[name]?.stringValue;
}
