import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { createApoloTestServer } from '../server/test_api_server.mjs';

let srv;
let baseUrl;

async function api(path, options = {}) {
  const res = await fetch(`${baseUrl}/api/v1${path}`, options);
  const text = await res.text();
  let json = null;
  try {
    json = JSON.parse(text);
  } catch {
    json = { raw: text };
  }
  return { status: res.status, json };
}

beforeAll(async () => {
  srv = createApoloTestServer({ dbPath: ':memory:' });
  const started = await srv.start(0, '127.0.0.1');
  baseUrl = started.baseUrl;
});

afterAll(async () => {
  if (srv) await srv.stop();
});

beforeEach(async () => {
  const res = await api('/test/reset', { method: 'POST' });
  expect(res.status).toBe(200);
});

describe('Apolo API <-> Isolated SQLite DB Integration', () => {
  it('returns taxonomy and home feed directly matching seeded SQLite tables', async () => {
    const tax = await api('/taxonomy');
    expect(tax.status).toBe(200);
    expect(tax.json.status).toBe('success');
    expect(tax.json.categories).toHaveLength(6);
    expect(tax.json.cities).toHaveLength(6);

    const dbCats = srv.db.prepare('SELECT COUNT(*) AS c FROM categories').get();
    expect(dbCats.c).toBe(6);

    const home = await api('/home');
    expect(home.status).toBe(200);
    expect(home.json.vip_ads.length).toBeGreaterThanOrEqual(1);
    expect(home.json.latest_ads).toHaveLength(4);
    expect(home.json.app_config.maintenance_mode).toBe(false);
  });

  it('completes Register -> DB persistence -> OTP verification -> Onboarding -> Profile sync', async () => {
    const reg = await api('/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'سارة التازي',
        email: 'sara@apolo.ma',
        phone: '0612345678',
        password: 'Password123!',
        password_confirmation: 'Password123!',
      }),
    });
    expect(reg.status).toBe(201);
    expect(reg.json.requires_otp).toBe(true);
    expect(reg.json.user.phone).toBe('+212612345678');

    const dbUserBefore = srv.db.prepare('SELECT * FROM users WHERE email = ?').get('sara@apolo.ma');
    expect(dbUserBefore).toBeTruthy();
    expect(dbUserBefore.email_verified_at).toBeNull();
    expect(dbUserBefore.onboarding_completed).toBe(0);

    // Duplicate email rejected cleanly
    const dup = await api('/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Duplicate',
        email: 'sara@apolo.ma',
        phone: '0612345679',
        password: 'Password123!',
        password_confirmation: 'Password123!',
      }),
    });
    expect(dup.status).toBe(422);

    const token = reg.json.token;
    const authHeaders = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    };

    // Wrong OTP rejected
    const badOtp = await api('/auth/otp/verify', {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({ code: '999999' }),
    });
    expect(badOtp.status).toBe(422);

    // Correct OTP marks verified in SQLite
    const goodOtp = await api('/auth/otp/verify', {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({ code: '123456' }),
    });
    expect(goodOtp.status).toBe(200);
    expect(goodOtp.json.user.email_verified_at).toBeTruthy();

    // Onboarding persists account_type, preferred_city_id, category_interests
    const onboard = await api('/auth/onboarding', {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({
        account_type: 'pro',
        preferred_city_id: 2,
        category_interests: [1, 3],
      }),
    });
    expect(onboard.status).toBe(200);
    expect(onboard.json.user.onboarding_completed).toBe(true);

    const profile = await api('/auth/profile', {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(profile.status).toBe(200);
    expect(profile.json.user.account_type).toBe('pro');
    expect(profile.json.user.preferred_city_id).toBe(2);
    expect(profile.json.user.category_interests).toEqual([1, 3]);
  });

  it('supports login by normalized Moroccan phone & rejects invalid credentials', async () => {
    const ok = await api('/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login: '0600000001', password: 'Password123!' }),
    });
    expect(ok.status).toBe(200);
    expect(ok.json.requires_otp).toBe(false);
    expect(ok.json.user.email).toBe('seller@apolo.ma');

    const bad = await api('/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login: 'seller@apolo.ma', password: 'WrongPassword!' }),
    });
    expect(bad.status).toBe(401);

    const empty = await api('/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login: '', password: '' }),
    });
    expect(empty.status).toBe(422);
  });

  it('creates ads, rejects negative price/unauthorized, filters ads, and increments DB views', async () => {
    // Unauthorized POST blocked
    const unauth = await api('/ads', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: 'إعلان بدون دخول', price: 100, category_id: 1, city_id: 1 }),
    });
    expect(unauth.status).toBe(401);

    const login = await api('/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login: 'seller@apolo.ma', password: 'Password123!' }),
    });
    const authHeaders = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${login.json.token}`,
    };

    // Negative price rejected
    const negAd = await api('/ads', {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({ title: 'إعلان بسعر سالب', price: -50, category_id: 3, city_id: 1 }),
    });
    expect(negAd.status).toBe(422);

    // Valid ad creation stored in DB
    const created = await api('/ads', {
      method: 'POST',
      headers: authHeaders,
      body: JSON.stringify({
        title: 'MacBook Pro M3 جديد',
        description: 'مقاس 14 بوصة مع الضمان',
        price: 16500,
        category_id: 3,
        city_id: 1,
        phone_call: '0666778899',
        negotiable: true,
      }),
    });
    expect(created.status).toBe(201);
    const adId = created.json.ad.id;
    expect(created.json.ad.phone_call).toBe('+212666778899');

    // Filter by query + category + city + price range
    const filtered = await api('/ads?category_id=3&city_id=1&price_min=10000&price_max=20000&query=MacBook');
    expect(filtered.status).toBe(200);
    expect(filtered.json.data.some((a) => a.id === adId)).toBe(true);

    // My ads endpoint
    const myAds = await api('/my-ads', { headers: { Authorization: `Bearer ${login.json.token}` } });
    expect(myAds.status).toBe(200);
    expect(myAds.json.data.some((a) => a.id === adId)).toBe(true);

    // Ad detail view increments views_count in SQLite
    const beforeRow = srv.db.prepare('SELECT views_count FROM ads WHERE id = ?').get(adId);
    const detail = await api(`/ads/${adId}`);
    expect(detail.status).toBe(200);
    const afterRow = srv.db.prepare('SELECT views_count FROM ads WHERE id = ?').get(adId);
    expect(afterRow.views_count).toBe(beforeRow.views_count + 1);
  });

  it('handles favorites toggle, saved searches, stores, notifications, boost payment, chat, logout and account deletion', async () => {
    // Register buyer so notifications exist and buyer can chat with seeded seller@apolo.ma (id 1)
    const reg = await api('/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'كريم المشتري',
        email: 'karim@apolo.ma',
        phone: '0655443322',
        password: 'Password123!',
        password_confirmation: 'Password123!',
      }),
    });
    const token = reg.json.token;
    const headers = {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    };

    // Favorites add & remove persisted in favorites table
    const favAdd = await api('/favorites/1/toggle', { method: 'POST', headers });
    expect(favAdd.status).toBe(200);
    expect(favAdd.json.is_favorite).toBe(true);

    const favList = await api('/favorites', { headers });
    expect(favList.json.data.map((a) => a.id)).toContain(1);

    const favRem = await api('/favorites/1/toggle', { method: 'POST', headers });
    expect(favRem.json.is_favorite).toBe(false);

    // Saved search & Stores
    const saved = await api('/saved-searches', {
      method: 'POST',
      headers,
      body: JSON.stringify({ title: 'سيارات الدار البيضاء', category_id: 1, city_id: 1, price_max: 200000 }),
    });
    expect(saved.status).toBe(201);

    const stores = await api('/stores?search=Auto');
    expect(stores.status).toBe(200);
    expect(stores.json.data.length).toBeGreaterThanOrEqual(1);

    // Notifications read-all
    const notifBefore = await api('/notifications', { headers });
    expect(notifBefore.json.unread_count).toBe(1);
    const readAll = await api('/notifications/read-all', { method: 'POST', headers });
    expect(readAll.status).toBe(200);
    const notifAfter = await api('/notifications', { headers });
    expect(notifAfter.json.unread_count).toBe(0);

    // Boost plans & VIP checkout updates ad is_vip and inserts ad_payments
    const plans = await api('/boost/plans');
    expect(plans.status).toBe(200);
    expect(plans.json.plans.length).toBeGreaterThanOrEqual(2);

    const boost = await api('/ads/2/boost/verify-iap', {
      method: 'POST',
      headers,
      body: JSON.stringify({ plan: 'vip_7d', platform: 'web', transaction_id: 'INT-TXN-1' }),
    });
    expect(boost.status).toBe(200);
    const dbAd2 = srv.db.prepare('SELECT is_vip FROM ads WHERE id = 2').get();
    expect(dbAd2.is_vip).toBe(1);
    const dbPay = srv.db.prepare('SELECT * FROM ad_payments WHERE transaction_id = ?').get('INT-TXN-1');
    expect(dbPay.amount).toBe(49);

    // Chat conversation & message persistence + empty message validation
    const chatStart = await api('/chat/start', {
      method: 'POST',
      headers,
      body: JSON.stringify({ ad_id: 1 }),
    });
    expect(chatStart.status).toBe(200);
    const convId = chatStart.json.conversation.id;

    const emptyMsg = await api(`/chat/conversations/${convId}/messages`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ body: '   ' }),
    });
    expect(emptyMsg.status).toBe(422);

    const sendMsg = await api(`/chat/conversations/${convId}/messages`, {
      method: 'POST',
      headers,
      body: JSON.stringify({ body: 'واش مازال متوفرة؟' }),
    });
    expect(sendMsg.status).toBe(201);

    const msgs = await api(`/chat/conversations/${convId}/messages`, { headers });
    expect(msgs.json.messages).toHaveLength(1);
    expect(msgs.json.messages[0].is_mine).toBe(true);

    // Update profile (name, bio, email, phone)
    const upd = await api('/auth/profile', {
      method: 'PUT',
      headers,
      body: JSON.stringify({
        name: 'كريم المعدل',
        bio: 'تاجر موثوق',
        email: 'karim.updated@apolo.ma',
        phone: '+212 6 44 55 66 77',
      }),
    });
    expect(upd.status).toBe(200);
    expect(upd.json.user.name).toBe('كريم المعدل');
    expect(upd.json.user.email).toBe('karim.updated@apolo.ma');
    expect(upd.json.user.phone).toBe('+212644556677');

    // Change password: wrong current password fails (422), valid current password succeeds (200)
    const badPwd = await api('/auth/password', {
      method: 'PUT',
      headers,
      body: JSON.stringify({
        current_password: 'WrongPassword!',
        password: 'NewPassword456!',
        password_confirmation: 'NewPassword456!',
      }),
    });
    expect(badPwd.status).toBe(422);

    const okPwd = await api('/auth/password', {
      method: 'PUT',
      headers,
      body: JSON.stringify({
        current_password: 'Password123!',
        password: 'NewPassword456!',
        password_confirmation: 'NewPassword456!',
      }),
    });
    expect(okPwd.status).toBe(200);

    // Delete account cascades DB user & sessions
    const del = await api('/auth/profile', { method: 'DELETE', headers });
    expect(del.status).toBe(200);
    const gone = srv.db.prepare('SELECT * FROM users WHERE email = ?').get('karim.updated@apolo.ma');
    expect(gone).toBeUndefined();

    // Token no longer works after account deletion
    const afterDel = await api('/auth/profile', { headers });
    expect(afterDel.status).toBe(401);
  });

  it('invalidates session token in SQLite on logout', async () => {
    const login = await api('/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ login: 'seller@apolo.ma', password: 'Password123!' }),
    });
    const token = login.json.token;
    const headers = { Authorization: `Bearer ${token}` };

    const logoutRes = await api('/auth/logout', { method: 'POST', headers });
    expect(logoutRes.status).toBe(200);

    const sessionRow = srv.db.prepare('SELECT * FROM sessions WHERE token = ?').get(token);
    expect(sessionRow).toBeUndefined();

    const profileRes = await api('/auth/profile', { headers });
    expect(profileRes.status).toBe(401);
  });
});
