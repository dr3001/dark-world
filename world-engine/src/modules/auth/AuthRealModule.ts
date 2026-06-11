import { WorldEngineModule } from "../../core/Module.js";
import { query } from "../../db.js";
import { randomBytes, scryptSync } from "crypto";

export class AuthRealModule extends WorldEngineModule {
  name = "AuthRealModule";
  private saltRounds = parseInt(process.env.PASSWORD_SALT_ROUNDS || "10");
  override async initialize() { console.log("[AuthRealModule] Initialized — email registration ready"); }

  hashPassword(password: string): string {
    const salt = randomBytes(16).toString("hex");
    const hash = scryptSync(password, salt, 64).toString("hex");
    return salt + ":" + hash;
  }
  verifyPassword(password: string, stored: string): boolean {
    const [salt, hash] = stored.split(":");
    const test = scryptSync(password, salt, 64).toString("hex");
    return hash === test;
  }
  async registerEmail(email: string, password: string, displayName: string) {
    const existing = await query("SELECT id FROM accounts_profile WHERE email = $1", [email]);
    if (existing.rows[0]) return { error: "Email already registered" };
    const hash = this.hashPassword(password);
    const user = (await query("INSERT INTO accounts_profile (id, email, display_name, password_hash, username) VALUES (gen_random_uuid(),$1,$2,$3,$4) RETURNING *", [email, displayName, hash, email.split("@")[0] + "_" + Date.now()])).rows[0];
    const token = randomBytes(32).toString("hex");
    await query("INSERT INTO email_verifications (user_id, token, email) VALUES ($1,$2,$3)", [user.id, token, email]);
    await query("INSERT INTO login_history (user_id, success) VALUES ($1, true)", [user.id]);
    return { user: { id: user.id, email: user.email, display_name: user.display_name }, verification_token: token };
  }
  async login(email: string, password: string, ip?: string, device?: string) {
    const user = (await query("SELECT * FROM accounts_profile WHERE email = $1", [email])).rows[0];
    if (!user || !user.password_hash) {
      if (user) await query("INSERT INTO login_history (user_id, ip, device, success, failure_reason) VALUES ($1,$2,$3,false,'invalid_password')", [user.id, ip, device]);
      return { error: "Invalid credentials" };
    }
    if (user.is_banned) return { error: "Account banned" };
    if (!this.verifyPassword(password, user.password_hash)) {
      await query("INSERT INTO login_history (user_id, ip, device, success, failure_reason) VALUES ($1,$2,$3,false,'wrong_password')", [user.id, ip, device]);
      return { error: "Invalid credentials" };
    }
    const token = randomBytes(48).toString("hex");
    await query("INSERT INTO auth_sessions (user_id, token, ip, device, platform) VALUES ($1,$2,$3,$4,$5)", [user.id, token, ip, device, "web"]);
    await query("INSERT INTO login_history (user_id, ip, device, success) VALUES ($1,$2,$3,true)", [user.id, ip, device]);
    await query("UPDATE accounts_profile SET last_login_at = NOW() WHERE id = $1", [user.id]);
    return { token, user: { id: user.id, email: user.email, display_name: user.display_name, role: user.role, vip_level: user.vip_level } };
  }
  async logout(token: string) {
    await query("UPDATE auth_sessions SET is_active = false WHERE token = $1", [token]);
  }
  async verifyEmail(token: string) {
    const v = (await query("SELECT * FROM email_verifications WHERE token = $1 AND verified_at IS NULL AND expires_at > NOW()", [token])).rows[0];
    if (!v) return { error: "Invalid or expired token" };
    await query("UPDATE email_verifications SET verified_at = NOW() WHERE id = $1", [v.id]);
    await query("UPDATE accounts_profile SET email_verified = true WHERE id = $1", [v.user_id]);
    return { verified: true };
  }
}
