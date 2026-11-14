import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';
import {
  validateEmail,
  normalizeMoroccanPhone,
  validatePassword,
  validateOtp,
  parseAdPrice,
} from '../src/apolo_core_logic.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_WEB_ROOT = path.resolve(__dirname, '../../apolo_mobile/build/web');
const E2E_APP_HTML = path.resolve(__dirname, './app_e2e_ui.html');

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ttf': 'font/ttf',
  '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml',
};

function hashPassword(password) {
  return crypto.createHash('sha256').update(`apolo_salt_${password}`).digest('hex');
}

function initSchema(db) {
  db.exec(`
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      phone TEXT,
      password_hash TEXT NOT NULL,
      email_verified_at TEXT,
      otp_code TEXT,
      account_type TEXT DEFAULT 'individual',
      preferred_city_id INTEGER,
      category_interests TEXT DEFAULT '[]',
      onboarding_completed INTEGER DEFAULT 0,
      bio TEXT DEFAULT '',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS sessions (
      token TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      name_ar TEXT NOT NULL,
      name_fr TEXT NOT NULL,
      slug TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS cities (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      name_ar TEXT NOT NULL,
      name_fr TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS stores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      city_id INTEGER NOT NULL,
      category_id INTEGER NOT NULL,
      is_verified INTEGER DEFAULT 1,
      description TEXT DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS ads (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      price REAL NOT NULL DEFAULT 0,
      category_id INTEGER NOT NULL,
      city_id INTEGER NOT NULL,
      phone_call TEXT DEFAULT '',
      phone_whatsapp TEXT DEFAULT '',
      negotiable INTEGER DEFAULT 0,
      free INTEGER DEFAULT 0,
      hide_phone INTEGER DEFAULT 0,
      is_vip INTEGER DEFAULT 0,
      is_featured INTEGER DEFAULT 0,
      views_count INTEGER DEFAULT 0,
      main_image TEXT DEFAULT '',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS favorites (
      user_id INTEGER NOT NULL,
      ad_id INTEGER NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, ad_id),
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      FOREIGN KEY (ad_id) REFERENCES ads(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS conversations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ad_id INTEGER NOT NULL,
      buyer_id INTEGER NOT NULL,
      seller_id INTEGER NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      conversation_id INTEGER NOT NULL,
      sender_id INTEGER NOT NULL,
      body TEXT NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      ad_id INTEGER,
      conversation_id INTEGER,
      is_read INTEGER DEFAULT 0,
      read_at TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS saved_searches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      query TEXT DEFAULT '',
      category_id INTEGER,
      city_id INTEGER,
      price_min REAL,
      price_max REAL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS ad_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ad_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      plan_id TEXT NOT NULL,
      platform TEXT NOT NULL,
      transaction_id TEXT NOT NULL,
      amount REAL NOT NULL,
      status TEXT DEFAULT 'paid',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (ad_id) REFERENCES ads(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_ads_cat_city_vip_id ON ads(category_id, city_id, is_vip DESC, id DESC);
    CREATE INDEX IF NOT EXISTS idx_ads_vip_id ON ads(is_vip DESC, id DESC);
    CREATE INDEX IF NOT EXISTS idx_ads_user_id ON ads(user_id, id DESC);
    CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
    CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
  `);
}

function seedDatabase(db) {
  db.exec(`
    DELETE FROM ad_payments;
    DELETE FROM saved_searches;
    DELETE FROM notifications;
    DELETE FROM messages;
    DELETE FROM conversations;
    DELETE FROM favorites;
    DELETE FROM ads;
    DELETE FROM stores;
    DELETE FROM sessions;
    DELETE FROM users;
    DELETE FROM cities;
    DELETE FROM categories;
    DELETE FROM sqlite_sequence;
  `);

  const insertCat = db.prepare(
    'INSERT INTO categories (id, name, name_ar, name_fr, slug) VALUES (?, ?, ?, ?, ?)'
  );
  const categories = [
    [1, 'Véhicules', 'وسائل النقل', 'Véhicules', 'auto'],
    [2, 'Immobilier', 'عقارات', 'Immobilier', 'immo'],
    [3, 'Informatique', 'إعلاميات وتقنية', 'Informatique', 'info'],
    [4, 'Téléphones', 'هواتف وتقنية', 'Téléphones', 'phones'],
    [5, 'Maison & Déco', 'أثاث وديكور', 'Maison & Déco', 'maison'],
    [6, 'Mode & Beauté', 'أزياء وجمال', 'Mode & Beauté', 'mode'],
  ];
  for (const c of categories) insertCat.run(...c);

  const insertCity = db.prepare(
    'INSERT INTO cities (id, name, name_ar, name_fr) VALUES (?, ?, ?, ?)'
  );
  const cities = [
    [1, 'Casablanca', 'الدار البيضاء', 'Casablanca'],
    [2, 'Rabat', 'الرباط', 'Rabat'],
    [3, 'Marrakech', 'مراكش', 'Marrakech'],
    [4, 'Tanger', 'طنجة', 'Tanger'],
    [5, 'Agadir', 'أكادير', 'Agadir'],
    [6, 'Fès', 'فاس', 'Fès'],
  ];
  for (const c of cities) insertCity.run(...c);

  // Seed verified seller account
  db.prepare(`
    INSERT INTO users (name, email, phone, password_hash, email_verified_at, otp_code, account_type, preferred_city_id, onboarding_completed, bio)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    'Karim Seller',
    'seller@apolo.ma',
    '+212600000001',
    hashPassword('Password123!'),
    '2026-01-01T00:00:00Z',
    '123456',
    'pro',
    1,
    1,
    'متجر سيارات وهواتف معتمد في الدار البيضاء'
  );

  // Seed stores
  const insertStore = db.prepare(
    'INSERT INTO stores (name, city_id, category_id, is_verified, description) VALUES (?, ?, ?, ?, ?)'
  );
  insertStore.run('Auto Prestige Casa', 1, 1, 1, 'سيارات فاخرة ومضمونة بالدار البيضاء');
  insertStore.run('TechStore Maroc', 2, 4, 1, 'هواتف وحواسيب أصلية مع الضمان');

  // Seed 4 ads
  const insertAd = db.prepare(`
    INSERT INTO ads (user_id, title, description, price, category_id, city_id, phone_call, phone_whatsapp, negotiable, is_vip, is_featured, views_count)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  insertAd.run(1, 'Mercedes C220 AMG 2022', 'سيارة نظيفة جداً بحالة الوكالة مع جميع الأوراق.', 295000, 1, 1, '+212600000001', '+212600000001', 1, 1, 1, 180);
  insertAd.run(1, 'iPhone 16 Pro Max 256Go', 'هاتف جديد بالعلبة الأصلية وضمان سنة.', 13500, 4, 2, '+212600000001', '+212600000001', 1, 0, 1, 240);
  insertAd.run(1, 'Appartement Moderne Maarif 110m²', 'شقة مشمسة 3 غرف وصالون بالمعاريف.', 1450000, 2, 1, '+212600000001', '+212600000001', 0, 1, 0, 95);
  insertAd.run(1, 'MacBook Pro M4 14" Neuf', 'حاسوب محمول احترافي للمطورين والمصممين.', 19800, 3, 3, '+212600000001', '+212600000001', 1, 0, 0, 62);
}

const BOOST_PLANS = [
  {
    id: 'vip_7d',
    iap_product_id: 'apolo_boost_vip_7d',
    name_ar: 'باقة VIP الذهبية (7 أيام)',
    name_fr: 'Pack VIP Or (7 jours)',
    price_mad: 49,
    features_ar: ['ظهور في الصدارة لمدة 7 أيام', 'شارة VIP ذهبية مميزة'],
    features_fr: ['Top des résultats pendant 7 jours', 'Badge VIP doré'],
  },
  {
    id: 'featured_15d',
    iap_product_id: 'apolo_boost_featured_15d',
    name_ar: 'باقة التمييز القصوى (15 يوم)',
    name_fr: 'Pack Boost Max (15 jours)',
    price_mad: 99,
    features_ar: ['أولوية في الصفحة الرئيسية', 'ظهور مضاعف في البحث'],
    features_fr: ['Priorité page accueil', 'Visibilité x5'],
  },
];

async function parseRequestBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  const buffer = Buffer.concat(chunks);
  if (buffer.length === 0) return {};

  const ct = String(req.headers['content-type'] || '').toLowerCase();
  if (ct.includes('multipart/form-data')) {
    const match = ct.match(/boundary=([^;]+)/i);
    if (!match) return {};
    const boundary = `--${match[1].replace(/^"|"$/g, '')}`;
    const raw = buffer.toString('latin1');
    const parts = raw.split(boundary).slice(1, -1);
    const fields = {};
    for (const part of parts) {
      const sepIdx = part.indexOf('\r\n\r\n');
      if (sepIdx === -1) continue;
      const headerPart = part.slice(0, sepIdx);
      let valuePart = part.slice(sepIdx + 4);
      if (valuePart.endsWith('\r\n')) valuePart = valuePart.slice(0, -2);
      const nameMatch = headerPart.match(/name="([^"]+)"/);
      if (!nameMatch) continue;
      const fieldName = nameMatch[1];
      if (/filename="/.test(headerPart)) continue;
      fields[fieldName] = Buffer.from(valuePart, 'latin1').toString('utf8');
    }
    return fields;
  }

  const text = buffer.toString('utf8').trim();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    return {};
  }
}

function formatUserRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    username: row.name.toLowerCase().replace(/[^a-z0-9]/g, '') || `user${row.id}`,
    email: row.email,
    phone: row.phone,
    email_verified: Boolean(row.email_verified_at),
    email_verified_at: row.email_verified_at,
    account_type: row.account_type || 'individual',
    preferred_city_id: row.preferred_city_id,
    category_interests: (() => {
      try {
        return JSON.parse(row.category_interests || '[]');
      } catch {
        return [];
      }
    })(),
    onboarding_completed: Boolean(row.onboarding_completed),
    bio: row.bio || '',
  };
}

function formatAdRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    user_id: row.user_id,
    title: row.title,
    description: row.description,
    price: row.price,
    price_formatted: row.free ? 'مجاني' : `${row.price} DH`,
    category_id: row.category_id,
    category_name: row.category_name || '',
    category: row.category_name
      ? { id: row.category_id, name_ar: row.category_name_ar, name_fr: row.category_name }
      : undefined,
    city_id: row.city_id,
    city_name: row.city_name_ar || row.city_name || '',
    city: row.city_name
      ? { id: row.city_id, name_ar: row.city_name_ar, name_fr: row.city_name }
      : undefined,
    phone_call: row.phone_call,
    phone_whatsapp: row.phone_whatsapp,
    negotiable: Boolean(row.negotiable),
    free: Boolean(row.free),
    hide_phone: Boolean(row.hide_phone),
    is_vip: Boolean(row.is_vip),
    is_featured: Boolean(row.is_featured),
    views_count: row.views_count,
    views: row.views_count,
    main_image: row.main_image || '',
    seller: row.seller_name ? { id: row.user_id, name: row.seller_name } : undefined,
    created_at: row.created_at,
  };
}

export function createApoloTestServer({
  dbPath = ':memory:',
  webRoot = DEFAULT_WEB_ROOT,
} = {}) {
  const db = new DatabaseSync(dbPath);
  initSchema(db);
  seedDatabase(db);

  const staticCache = new Map();
  let taxonomyCache = null;

  function getTaxonomy() {
    if (!taxonomyCache) {
      taxonomyCache = {
        categories: db.prepare('SELECT * FROM categories ORDER BY id ASC').all(),
        cities: db.prepare('SELECT * FROM cities ORDER BY id ASC').all(),
      };
    }
    return taxonomyCache;
  }

  const adSelectSql = `
    SELECT a.*, c.name_ar AS category_name_ar, c.name_fr AS category_name,
           ci.name_ar AS city_name_ar, ci.name_fr AS city_name, u.name AS seller_name
    FROM ads a
    LEFT JOIN categories c ON c.id = a.category_id
    LEFT JOIN cities ci ON ci.id = a.city_id
    LEFT JOIN users u ON u.id = a.user_id
  `;

  function sendJson(res, statusCode, payload) {
    res.writeHead(statusCode, {
      'Content-Type': 'application/json; charset=utf-8',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Cache-Control': 'no-store',
    });
    res.end(JSON.stringify(payload));
  }

  function getAuthUser(req) {
    const auth = String(req.headers.authorization || '');
    if (!auth.startsWith('Bearer ')) return null;
    const token = auth.slice(7).trim();
    if (!token) return null;
    const row = db
      .prepare(
        `SELECT u.* FROM sessions s JOIN users u ON u.id = s.user_id WHERE s.token = ?`
      )
      .get(token);
    return row ? { token, user: row } : null;
  }

  function serveCachedFile(res, filePath, contentType) {
    let cached = staticCache.get(filePath);
    if (!cached) {
      const stat = fs.statSync(filePath);
      if (stat.size <= 512 * 1024) {
        cached = fs.readFileSync(filePath);
        staticCache.set(filePath, cached);
      }
    }
    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-store',
    });
    if (cached) {
      res.end(cached);
    } else {
      fs.createReadStream(filePath).pipe(res);
    }
  }

  function serveStatic(req, res, pathname) {
    if (pathname === '/app' || pathname === '/app/') {
      serveCachedFile(res, E2E_APP_HTML, 'text/html; charset=utf-8');
      return;
    }

    if (pathname === '/privacy') pathname = '/privacy.html';
    if (pathname === '/delete-account') pathname = '/delete-account.html';

    const safeRel = pathname.replace(/^\/+/, '');
    let targetFile = path.resolve(webRoot, safeRel || 'index.html');
    if (!targetFile.startsWith(path.resolve(webRoot))) {
      res.writeHead(403).end('Forbidden');
      return;
    }
    if (!fs.existsSync(targetFile) || fs.statSync(targetFile).isDirectory()) {
      targetFile = path.join(webRoot, 'index.html');
    }
    if (!fs.existsSync(targetFile)) {
      res.writeHead(404).end('Not found');
      return;
    }
    const ext = path.extname(targetFile).toLowerCase();
    serveCachedFile(res, targetFile, MIME_TYPES[ext] || 'application/octet-stream');
  }

  const server = http.createServer(async (req, res) => {
    try {
      if (req.method === 'OPTIONS') {
        res.writeHead(204, {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        });
        res.end();
        return;
      }

      const urlObj = new URL(req.url, 'http://127.0.0.1');
      const pathname = decodeURIComponent(urlObj.pathname);

      if (!pathname.startsWith('/api/v1')) {
        serveStatic(req, res, pathname);
        return;
      }

      const route = pathname.slice('/api/v1'.length) || '/';
      const method = req.method.toUpperCase();

      // Test reset helper
      if (method === 'POST' && route === '/test/reset') {
        seedDatabase(db);
        taxonomyCache = null;
        return sendJson(res, 200, { status: 'success', message: 'Database reset' });
      }

      // Taxonomy
      if (method === 'GET' && route === '/taxonomy') {
        const { categories, cities } = getTaxonomy();
        return sendJson(res, 200, { status: 'success', categories, cities });
      }

      // Home feed
      if (method === 'GET' && route === '/home') {
        const latestAds = db
          .prepare(`${adSelectSql} ORDER BY a.id DESC LIMIT 20`)
          .all()
          .map(formatAdRow);
        const vipAds = db
          .prepare(`${adSelectSql} WHERE a.is_vip = 1 ORDER BY a.id DESC LIMIT 10`)
          .all()
          .map(formatAdRow);
        const featuredAds = db
          .prepare(`${adSelectSql} WHERE a.is_featured = 1 ORDER BY a.id DESC LIMIT 10`)
          .all()
          .map(formatAdRow);
        const { categories } = getTaxonomy();
        return sendJson(res, 200, {
          status: 'success',
          vip_ads: vipAds,
          featured_ads: featuredAds,
          latest_ads: latestAds,
          categories,
          app_config: {
            maintenance_mode: false,
            min_version: '1.0.0',
            latest_version: '2.0.0',
            force_update: false,
            announcement_active: true,
          },
        });
      }

      // Register
      if (method === 'POST' && route === '/auth/register') {
        const body = await parseRequestBody(req);
        const name = String(body.name || '').trim();
        const email = String(body.email || '').trim().toLowerCase();
        const phone = normalizeMoroccanPhone(body.phone);
        const password = String(body.password || '');
        const confirmation = String(body.password_confirmation || '');

        if (
          name.length < 2 ||
          !validateEmail(email) ||
          !phone ||
          !validatePassword(password) ||
          password !== confirmation
        ) {
          return sendJson(res, 422, {
            status: 'error',
            message: 'تحقق من البيانات المدخلة: الاسم أو البريد أو الهاتف أو كلمة المرور غير صالحة.',
          });
        }

        const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
        if (existing) {
          return sendJson(res, 422, {
            status: 'error',
            message: 'هذا البريد الإلكتروني مستخدم بالفعل.',
          });
        }

        const result = db
          .prepare(
            `INSERT INTO users (name, email, phone, password_hash, otp_code) VALUES (?, ?, ?, ?, ?)`
          )
          .run(name, email, phone, hashPassword(password), '123456');
        const userId = Number(result.lastInsertRowid);
        const token = crypto.randomBytes(24).toString('hex');
        db.prepare('INSERT INTO sessions (token, user_id) VALUES (?, ?)').run(token, userId);

        db.prepare(
          `INSERT INTO notifications (user_id, type, title, body) VALUES (?, ?, ?, ?)`
        ).run(userId, 'activity', 'مرحباً بك في Apolo.ma', 'أكمل تفعيل حسابك لتبدأ النشر والتواصل.');

        const userRow = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
        return sendJson(res, 201, {
          status: 'success',
          requires_otp: true,
          otp_sent: true,
          token,
          user: formatUserRow(userRow),
        });
      }

      // Login
      if (method === 'POST' && route === '/auth/login') {
        const body = await parseRequestBody(req);
        const rawLogin = String(body.login || body.email || body.phone || '').trim();
        const password = String(body.password || '');
        if (!rawLogin || !password) {
          return sendJson(res, 422, { status: 'error', message: 'بيانات الدخول مطلوبة.' });
        }

        const normalizedPhone = normalizeMoroccanPhone(rawLogin);
        const userRow = normalizedPhone
          ? db.prepare('SELECT * FROM users WHERE phone = ?').get(normalizedPhone)
          : db.prepare('SELECT * FROM users WHERE email = ?').get(rawLogin.toLowerCase());

        if (!userRow || userRow.password_hash !== hashPassword(password)) {
          return sendJson(res, 401, {
            status: 'error',
            message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
          });
        }

        const token = crypto.randomBytes(24).toString('hex');
        db.prepare('INSERT INTO sessions (token, user_id) VALUES (?, ?)').run(token, userRow.id);
        const needsOtp = !userRow.email_verified_at;
        return sendJson(res, 200, {
          status: 'success',
          requires_otp: needsOtp,
          otp_sent: true,
          token,
          user: formatUserRow(userRow),
        });
      }

      // OTP Verify
      if (method === 'POST' && route === '/auth/otp/verify') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const body = await parseRequestBody(req);
        const code = String(body.code || '').trim();
        if (!validateOtp(code) || code !== (auth.user.otp_code || '123456')) {
          return sendJson(res, 422, {
            status: 'error',
            message: 'رمز التحقق غير صحيح أو منتهي الصلاحية.',
          });
        }
        const nowIso = new Date().toISOString();
        db.prepare('UPDATE users SET email_verified_at = ? WHERE id = ?').run(nowIso, auth.user.id);
        const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(auth.user.id);
        return sendJson(res, 200, { status: 'success', user: formatUserRow(updated) });
      }

      // OTP Resend
      if (method === 'POST' && route === '/auth/otp/resend') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        db.prepare('UPDATE users SET otp_code = ? WHERE id = ?').run('123456', auth.user.id);
        return sendJson(res, 200, { status: 'success', message: 'OTP sent' });
      }

      // Onboarding
      if (method === 'POST' && route === '/auth/onboarding') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const body = await parseRequestBody(req);
        const accType = body.account_type;
        const cityId = Number(body.preferred_city_id);
        const interests = Array.isArray(body.category_interests) ? body.category_interests : [];
        if (
          !['individual', 'pro'].includes(accType) ||
          !Number.isInteger(cityId) ||
          cityId <= 0 ||
          interests.length === 0
        ) {
          return sendJson(res, 422, { status: 'error', message: 'بيانات الإعداد غير مكتملة.' });
        }
        db.prepare(
          `UPDATE users SET account_type = ?, preferred_city_id = ?, category_interests = ?, onboarding_completed = 1 WHERE id = ?`
        ).run(accType, cityId, JSON.stringify(interests), auth.user.id);
        const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(auth.user.id);
        return sendJson(res, 200, { status: 'success', user: formatUserRow(updated) });
      }

      // Profile GET / PUT / DELETE
      if (route === '/auth/profile') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        if (method === 'GET') {
          return sendJson(res, 200, { status: 'success', user: formatUserRow(auth.user) });
        }
        if (method === 'PUT') {
          const body = await parseRequestBody(req);
          const nextName = String(body.name ?? auth.user.name).trim();
          const nextBio = String(body.bio ?? auth.user.bio ?? '');
          const nextEmail = body.email !== undefined ? String(body.email).trim().toLowerCase() : auth.user.email;
          const rawPhone = body.phone !== undefined ? String(body.phone).trim() : auth.user.phone;
          if (nextName.length < 2) {
            return sendJson(res, 422, { status: 'error', message: 'الاسم قصير جداً.' });
          }
          if (!validateEmail(nextEmail)) {
            return sendJson(res, 422, { status: 'error', message: 'البريد الإلكتروني غير صالح.' });
          }
          let nextPhone = auth.user.phone;
          if (body.phone !== undefined && rawPhone.length > 0) {
            nextPhone = normalizeMoroccanPhone(rawPhone);
            if (!nextPhone) {
              return sendJson(res, 422, { status: 'error', message: 'رقم الهاتف غير صالح.' });
            }
          }
          const dupEmail = db
            .prepare('SELECT id FROM users WHERE email = ? AND id != ?')
            .get(nextEmail, auth.user.id);
          if (dupEmail) {
            return sendJson(res, 422, { status: 'error', message: 'البريد الإلكتروني مستخدم بالفعل.' });
          }
          db.prepare('UPDATE users SET name = ?, bio = ?, email = ?, phone = ? WHERE id = ?').run(
            nextName,
            nextBio,
            nextEmail,
            nextPhone,
            auth.user.id
          );
          const updated = db.prepare('SELECT * FROM users WHERE id = ?').get(auth.user.id);
          return sendJson(res, 200, { status: 'success', user: formatUserRow(updated) });
        }
        if (method === 'DELETE') {
          db.prepare('DELETE FROM users WHERE id = ?').run(auth.user.id);
          return sendJson(res, 200, { status: 'success', message: 'Account deleted' });
        }
      }

      // Change Password (Authenticated)
      if ((method === 'PUT' || method === 'POST') && route === '/auth/password') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const body = await parseRequestBody(req);
        const currentPassword = String(body.current_password ?? '');
        const nextPassword = String(body.password ?? '');
        const confirmation = String(body.password_confirmation ?? nextPassword);
        if (hashPassword(currentPassword) !== auth.user.password_hash) {
          return sendJson(res, 422, { status: 'error', message: 'كلمة المرور الحالية غير صحيحة.' });
        }
        if (!validatePassword(nextPassword) || nextPassword !== confirmation) {
          return sendJson(res, 422, { status: 'error', message: 'كلمة المرور الجديدة غير صالحة أو غير متطابقة.' });
        }
        db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(
          hashPassword(nextPassword),
          auth.user.id
        );
        return sendJson(res, 200, { status: 'success', message: 'Password updated' });
      }

      // Logout
      if (method === 'POST' && route === '/auth/logout') {
        const auth = getAuthUser(req);
        if (auth) {
          db.prepare('DELETE FROM sessions WHERE token = ?').run(auth.token);
        }
        return sendJson(res, 200, { status: 'success' });
      }

      // Forgot password
      if (method === 'POST' && route === '/auth/forgot-password') {
        const body = await parseRequestBody(req);
        const email = String(body.email || body.login || '').trim();
        if (!validateEmail(email)) {
          return sendJson(res, 422, { status: 'error', message: 'بريد إلكتروني غير صالح.' });
        }
        return sendJson(res, 200, { status: 'success', message: 'Instructions sent' });
      }

      // Ads List & Create
      if (route === '/ads') {
        if (method === 'GET') {
          const params = urlObj.searchParams;
          const clauses = [];
          const bindings = [];

          const catId = Number(params.get('category_id'));
          if (Number.isInteger(catId) && catId > 0) {
            clauses.push('a.category_id = ?');
            bindings.push(catId);
          }
          const cityId = Number(params.get('city_id'));
          if (Number.isInteger(cityId) && cityId > 0) {
            clauses.push('a.city_id = ?');
            bindings.push(cityId);
          }
          const sellerId = Number(params.get('seller_id'));
          if (Number.isInteger(sellerId) && sellerId > 0) {
            clauses.push('a.user_id = ?');
            bindings.push(sellerId);
          }
          const pMin = params.get('price_min');
          if (pMin !== null && pMin !== '' && Number.isFinite(Number(pMin))) {
            clauses.push('a.price >= ?');
            bindings.push(Number(pMin));
          }
          const pMax = params.get('price_max');
          if (pMax !== null && pMax !== '' && Number.isFinite(Number(pMax))) {
            clauses.push('a.price <= ?');
            bindings.push(Number(pMax));
          }
          const q = String(params.get('query') || '').trim();
          if (q) {
            clauses.push('(LOWER(a.title) LIKE ? OR LOWER(a.description) LIKE ?)');
            bindings.push(`%${q.toLowerCase()}%`, `%${q.toLowerCase()}%`);
          }

          const whereSql = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
          const page = Math.max(1, Number(params.get('page')) || 1);
          const perPage = Math.max(1, Math.min(100, Number(params.get('per_page')) || 20));
          const offset = (page - 1) * perPage;

          const countRow = db
            .prepare(`SELECT COUNT(*) AS total FROM ads a ${whereSql}`)
            .get(...bindings);
          const total = countRow ? countRow.total : 0;

          const rows = db
            .prepare(`
              SELECT a.*, c.name_ar AS category_name_ar, c.name_fr AS category_name,
                     ci.name_ar AS city_name_ar, ci.name_fr AS city_name, u.name AS seller_name
              FROM ads a
              LEFT JOIN categories c ON c.id = a.category_id
              LEFT JOIN cities ci ON ci.id = a.city_id
              LEFT JOIN users u ON u.id = a.user_id
              ${whereSql}
              ORDER BY a.is_vip DESC, a.id DESC
              LIMIT ? OFFSET ?
            `)
            .all(...bindings, perPage, offset)
            .map(formatAdRow);

          return sendJson(res, 200, {
            status: 'success',
            data: rows,
            meta: {
              current_page: page,
              last_page: Math.max(1, Math.ceil(total / perPage)),
              total,
            },
          });
        }

        if (method === 'POST') {
          const auth = getAuthUser(req);
          if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
          const body = await parseRequestBody(req);
          const title = String(body.title || '').trim();
          const description = String(body.description || '').trim() || `${title} — متوفر على أبولو`;
          const isFree = body.free === 1 || body.free === '1' || body.free === true;
          const parsedPrice = isFree ? 0 : parseAdPrice(body.price);
          const categoryId = Number(body.category_id);
          const cityId = Number(body.city_id);

          if (
            title.length < 3 ||
            parsedPrice === null ||
            parsedPrice < 0 ||
            !Number.isInteger(categoryId) ||
            categoryId <= 0 ||
            !Number.isInteger(cityId) ||
            cityId <= 0
          ) {
            return sendJson(res, 422, {
              status: 'error',
              message: 'بيانات الإعلان غير صالحة (العنوان أو السعر أو القسم أو المدينة).',
            });
          }

          const phone = normalizeMoroccanPhone(body.phone_call || '') || auth.user.phone || '';
          const resInsert = db
            .prepare(`
              INSERT INTO ads (user_id, title, description, price, category_id, city_id, phone_call, phone_whatsapp, negotiable, free, hide_phone)
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `)
            .run(
              auth.user.id,
              title,
              description,
              parsedPrice,
              categoryId,
              cityId,
              phone,
              phone,
              body.negotiable ? 1 : 0,
              isFree ? 1 : 0,
              body.hide_phone ? 1 : 0
            );
          const newId = Number(resInsert.lastInsertRowid);
          const created = db
            .prepare(`
              SELECT a.*, c.name_ar AS category_name_ar, c.name_fr AS category_name,
                     ci.name_ar AS city_name_ar, ci.name_fr AS city_name, u.name AS seller_name
              FROM ads a
              LEFT JOIN categories c ON c.id = a.category_id
              LEFT JOIN cities ci ON ci.id = a.city_id
              LEFT JOIN users u ON u.id = a.user_id
              WHERE a.id = ?
            `)
            .get(newId);

          return sendJson(res, 201, { status: 'success', ad: formatAdRow(created) });
        }
      }

      // Ad details & Boost IAP
      const adBoostMatch = route.match(/^\/ads\/(\d+)\/boost\/verify-iap$/);
      if (method === 'POST' && adBoostMatch) {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const adId = Number(adBoostMatch[1]);
        const adRow = db.prepare('SELECT * FROM ads WHERE id = ?').get(adId);
        if (!adRow) return sendJson(res, 404, { status: 'error', message: 'Ad not found' });

        const body = await parseRequestBody(req);
        const plan = BOOST_PLANS.find((p) => p.id === body.plan) || BOOST_PLANS[0];
        db.prepare(
          `INSERT INTO ad_payments (ad_id, user_id, plan_id, platform, transaction_id, amount, status)
           VALUES (?, ?, ?, ?, ?, ?, ?)`
        ).run(
          adId,
          auth.user.id,
          plan.id,
          String(body.platform || 'web'),
          String(body.transaction_id || `TXN-${Date.now()}`),
          plan.price_mad,
          'paid'
        );
        db.prepare('UPDATE ads SET is_vip = 1 WHERE id = ?').run(adId);
        return sendJson(res, 200, {
          status: 'success',
          message: 'تم تمييز إعلانك بنجاح!',
          ad_id: adId,
          plan: plan.id,
        });
      }

      const adDetailMatch = route.match(/^\/ads\/(\d+)$/);
      if (method === 'GET' && adDetailMatch) {
        const adId = Number(adDetailMatch[1]);
        const existing = db.prepare('SELECT id FROM ads WHERE id = ?').get(adId);
        if (!existing) return sendJson(res, 404, { status: 'error', message: 'Ad not found' });

        db.prepare('UPDATE ads SET views_count = views_count + 1 WHERE id = ?').run(adId);
        const adRow = db
          .prepare(`
            SELECT a.*, c.name_ar AS category_name_ar, c.name_fr AS category_name,
                   ci.name_ar AS city_name_ar, ci.name_fr AS city_name, u.name AS seller_name
            FROM ads a
            LEFT JOIN categories c ON c.id = a.category_id
            LEFT JOIN cities ci ON ci.id = a.city_id
            LEFT JOIN users u ON u.id = a.user_id
            WHERE a.id = ?
          `)
          .get(adId);
        const related = db
          .prepare(`
            SELECT a.*, c.name_ar AS category_name_ar, c.name_fr AS category_name,
                   ci.name_ar AS city_name_ar, ci.name_fr AS city_name, u.name AS seller_name
            FROM ads a
            LEFT JOIN categories c ON c.id = a.category_id
            LEFT JOIN cities ci ON ci.id = a.city_id
            LEFT JOIN users u ON u.id = a.user_id
            WHERE a.id != ?
            LIMIT 4
          `)
          .all(adId)
          .map(formatAdRow);

        return sendJson(res, 200, {
          status: 'success',
          ad: formatAdRow(adRow),
          related_ads: related,
        });
      }

      // My Ads
      if (method === 'GET' && route === '/my-ads') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const rows = db
          .prepare(`
            SELECT a.*, c.name_ar AS category_name_ar, c.name_fr AS category_name,
                   ci.name_ar AS city_name_ar, ci.name_fr AS city_name, u.name AS seller_name
            FROM ads a
            LEFT JOIN categories c ON c.id = a.category_id
            LEFT JOIN cities ci ON ci.id = a.city_id
            LEFT JOIN users u ON u.id = a.user_id
            WHERE a.user_id = ?
            ORDER BY a.id DESC
          `)
          .all(auth.user.id)
          .map(formatAdRow);
        return sendJson(res, 200, { status: 'success', data: rows });
      }

      // Favorites
      if (method === 'GET' && route === '/favorites') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const rows = db
          .prepare(`
            SELECT a.*, c.name_ar AS category_name_ar, c.name_fr AS category_name,
                   ci.name_ar AS city_name_ar, ci.name_fr AS city_name, u.name AS seller_name
            FROM favorites f
            JOIN ads a ON a.id = f.ad_id
            LEFT JOIN categories c ON c.id = a.category_id
            LEFT JOIN cities ci ON ci.id = a.city_id
            LEFT JOIN users u ON u.id = a.user_id
            WHERE f.user_id = ?
            ORDER BY f.created_at DESC
          `)
          .all(auth.user.id)
          .map(formatAdRow);
        return sendJson(res, 200, { status: 'success', data: rows });
      }

      const favToggleMatch = route.match(/^\/favorites\/(\d+)\/toggle$/);
      if (method === 'POST' && favToggleMatch) {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const adId = Number(favToggleMatch[1]);
        const adExists = db.prepare('SELECT id FROM ads WHERE id = ?').get(adId);
        if (!adExists) return sendJson(res, 404, { status: 'error', message: 'Ad not found' });

        const existing = db
          .prepare('SELECT 1 FROM favorites WHERE user_id = ? AND ad_id = ?')
          .get(auth.user.id, adId);
        if (existing) {
          db.prepare('DELETE FROM favorites WHERE user_id = ? AND ad_id = ?').run(auth.user.id, adId);
          return sendJson(res, 200, { status: 'success', is_favorite: false });
        } else {
          db.prepare('INSERT INTO favorites (user_id, ad_id) VALUES (?, ?)').run(auth.user.id, adId);
          return sendJson(res, 200, { status: 'success', is_favorite: true });
        }
      }

      // Notifications
      if (method === 'GET' && route === '/notifications') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const list = db
          .prepare('SELECT * FROM notifications WHERE user_id = ? ORDER BY id DESC')
          .all(auth.user.id)
          .map((n) => ({ ...n, is_read: Boolean(n.is_read) }));
        const unreadCount = list.filter((n) => !n.is_read).length;
        return sendJson(res, 200, {
          status: 'success',
          notifications: list,
          unread_count: unreadCount,
        });
      }

      if (method === 'POST' && route === '/notifications/read-all') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        db.prepare('UPDATE notifications SET is_read = 1, read_at = ? WHERE user_id = ?').run(
          new Date().toISOString(),
          auth.user.id
        );
        return sendJson(res, 200, { status: 'success' });
      }

      const notifReadMatch = route.match(/^\/notifications\/(\d+)\/read$/);
      if (method === 'POST' && notifReadMatch) {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        db.prepare('UPDATE notifications SET is_read = 1, read_at = ? WHERE id = ? AND user_id = ?').run(
          new Date().toISOString(),
          Number(notifReadMatch[1]),
          auth.user.id
        );
        return sendJson(res, 200, { status: 'success' });
      }

      // Chat
      if (method === 'GET' && route === '/chat/conversations') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const rows = db
          .prepare(`
            SELECT c.*, a.title AS ad_title, a.price AS ad_price,
                   u.name AS peer_name, u.id AS peer_id
            FROM conversations c
            JOIN ads a ON a.id = c.ad_id
            JOIN users u ON u.id = CASE WHEN c.buyer_id = ? THEN c.seller_id ELSE c.buyer_id END
            WHERE c.buyer_id = ? OR c.seller_id = ?
            ORDER BY c.id DESC
          `)
          .all(auth.user.id, auth.user.id, auth.user.id);
        return sendJson(res, 200, { status: 'success', conversations: rows });
      }

      if (method === 'POST' && route === '/chat/start') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const body = await parseRequestBody(req);
        const adId = Number(body.ad_id);
        const ad = db.prepare('SELECT * FROM ads WHERE id = ?').get(adId);
        if (!ad) return sendJson(res, 404, { status: 'error', message: 'Ad not found' });

        let conv = db
          .prepare('SELECT * FROM conversations WHERE ad_id = ? AND buyer_id = ?')
          .get(adId, auth.user.id);
        if (!conv) {
          const ins = db
            .prepare('INSERT INTO conversations (ad_id, buyer_id, seller_id) VALUES (?, ?, ?)')
            .run(adId, auth.user.id, ad.user_id);
          conv = db.prepare('SELECT * FROM conversations WHERE id = ?').get(Number(ins.lastInsertRowid));
        }
        const seller = db.prepare('SELECT id, name FROM users WHERE id = ?').get(ad.user_id);
        return sendJson(res, 200, {
          status: 'success',
          conversation: { ...conv, other_user: seller },
        });
      }

      const chatMsgMatch = route.match(/^\/chat\/conversations\/(\d+)\/messages$/);
      if (chatMsgMatch) {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const convId = Number(chatMsgMatch[1]);
        const conv = db.prepare('SELECT * FROM conversations WHERE id = ?').get(convId);
        if (!conv) return sendJson(res, 404, { status: 'error', message: 'Conversation not found' });

        if (method === 'GET') {
          const msgs = db
            .prepare('SELECT * FROM messages WHERE conversation_id = ? ORDER BY id ASC')
            .all(convId)
            .map((m) => ({ ...m, is_mine: m.sender_id === auth.user.id, type: 'text' }));
          return sendJson(res, 200, { status: 'success', messages: msgs });
        }

        if (method === 'POST') {
          const body = await parseRequestBody(req);
          const text = String(body.body || body.message || '').trim();
          if (!text) return sendJson(res, 422, { status: 'error', message: 'Message cannot be empty' });
          const ins = db
            .prepare('INSERT INTO messages (conversation_id, sender_id, body) VALUES (?, ?, ?)')
            .run(convId, auth.user.id, text);
          const created = db
            .prepare('SELECT * FROM messages WHERE id = ?')
            .get(Number(ins.lastInsertRowid));
          return sendJson(res, 201, {
            status: 'success',
            message: { ...created, is_mine: true, type: 'text' },
          });
        }
      }

      // Stores
      if (method === 'GET' && route === '/stores') {
        const search = String(urlObj.searchParams.get('search') || '').trim().toLowerCase();
        const rows = search
          ? db
              .prepare('SELECT * FROM stores WHERE LOWER(name) LIKE ? ORDER BY id ASC')
              .all(`%${search}%`)
          : db.prepare('SELECT * FROM stores ORDER BY id ASC').all();
        return sendJson(res, 200, {
          status: 'success',
          data: rows,
          meta: { current_page: 1, last_page: 1 },
        });
      }

      // Saved searches
      if (method === 'POST' && route === '/saved-searches') {
        const auth = getAuthUser(req);
        if (!auth) return sendJson(res, 401, { status: 'error', message: 'Unauthorized' });
        const body = await parseRequestBody(req);
        const ins = db
          .prepare(
            `INSERT INTO saved_searches (user_id, title, query, category_id, city_id, price_min, price_max)
             VALUES (?, ?, ?, ?, ?, ?, ?)`
          )
          .run(
            auth.user.id,
            String(body.title || 'بحث محفوظ'),
            String(body.query || ''),
            body.category_id ?? null,
            body.city_id ?? null,
            body.price_min ?? null,
            body.price_max ?? null
          );
        return sendJson(res, 201, {
          status: 'success',
          id: Number(ins.lastInsertRowid),
        });
      }

      // Boost plans
      if (method === 'GET' && route === '/boost/plans') {
        return sendJson(res, 200, { status: 'success', plans: BOOST_PLANS });
      }

      return sendJson(res, 404, { status: 'error', message: `Route not found: ${method} ${route}` });
    } catch (err) {
      return sendJson(res, 500, { status: 'error', message: err?.message || 'Internal error' });
    }
  });

  return {
    server,
    db,
    start(port = 0, host = '127.0.0.1') {
      return new Promise((resolve) => {
        server.listen(port, host, () => {
          const addr = server.address();
          resolve({
            port: typeof addr === 'object' ? addr.port : port,
            host,
            baseUrl: `http://${host}:${typeof addr === 'object' ? addr.port : port}`,
          });
        });
      });
    },
    stop() {
      return new Promise((resolve) => {
        server.close(() => {
          try {
            db.close();
          } catch (_) {}
          resolve();
        });
      });
    },
  };
}
