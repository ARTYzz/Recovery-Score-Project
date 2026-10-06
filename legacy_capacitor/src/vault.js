import { emptyData } from "./core.js";
const encoder = new TextEncoder(),
  decoder = new TextDecoder();
// Passing a large byte array with `...bytes` creates one function argument per
// byte and overflows the JavaScript call stack once meal photos are present.
// Convert fixed-size chunks instead so vault size does not affect stack depth.
const b64 = (bytes) => {
  const chunkSize = 0x8000;
  let binary = "";
  for (let offset = 0; offset < bytes.length; offset += chunkSize)
    binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));
  return btoa(binary);
};
const unb64 = (text) => Uint8Array.from(atob(text), (x) => x.charCodeAt(0));
export class AthleteVault {
  constructor(storage = localStorage) {
    this.storage = storage;
    this.key = null;
    this.data = null;
  }
  exists() {
    return !!this.storage.getItem("boxer-vault-v1");
  }
  async derive(passphrase, salt) {
    const material = await crypto.subtle.importKey(
      "raw",
      encoder.encode(passphrase),
      "PBKDF2",
      false,
      ["deriveKey"],
    );
    return crypto.subtle.deriveKey(
      { name: "PBKDF2", salt, iterations: 210000, hash: "SHA-256" },
      material,
      { name: "AES-GCM", length: 256 },
      false,
      ["encrypt", "decrypt"],
    );
  }
  async create(passphrase, data = emptyData()) {
    if (passphrase.length < 8)
      throw Error("Use at least 8 characters for the local passphrase.");
    const salt = crypto.getRandomValues(new Uint8Array(16));
    this.key = await this.derive(passphrase, salt);
    this.salt = salt;
    this.data = data;
    await this.save();
  }
  async unlock(passphrase) {
    const record = JSON.parse(this.storage.getItem("boxer-vault-v1") || "null");
    if (!record) throw Error("No athlete profile found.");
    const salt = unb64(record.salt),
      key = await this.derive(passphrase, salt);
    try {
      const plain = await crypto.subtle.decrypt(
        { name: "AES-GCM", iv: unb64(record.iv) },
        key,
        unb64(record.cipher),
      );
      this.key = key;
      this.salt = salt;
      this.data = JSON.parse(decoder.decode(plain));
      return this.data;
    } catch {
      throw Error("Passphrase is incorrect or data is damaged.");
    }
  }
  async save() {
    if (!this.key || !this.data) throw Error("Vault is locked.");
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const cipher = await crypto.subtle.encrypt(
      { name: "AES-GCM", iv },
      this.key,
      encoder.encode(JSON.stringify(this.data)),
    );
    this.storage.setItem(
      "boxer-vault-v1",
      JSON.stringify({
        version: 1,
        salt: b64(this.salt),
        iv: b64(iv),
        cipher: b64(new Uint8Array(cipher)),
      }),
    );
  }
  lock() {
    this.key = null;
    this.data = null;
  }
  delete() {
    this.storage.removeItem("boxer-vault-v1");
    this.lock();
  }
}
