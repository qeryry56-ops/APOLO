import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Trend } from 'k6/metrics';

const BASE_URL = __ENV.APOLO_BASE_URL || 'http://127.0.0.1:8788';

const homeTrend = new Trend('apolo_home_ms');
const adsListTrend = new Trend('apolo_ads_list_ms');
const adDetailTrend = new Trend('apolo_ad_detail_ms');
const loginTrend = new Trend('apolo_login_ms');
const createAdTrend = new Trend('apolo_create_ad_ms');
const webAppTrend = new Trend('apolo_webapp_ms');

export const options = {
  stages: [
    { duration: '5s', target: 10 },
    { duration: '8s', target: 30 },
    { duration: '8s', target: 60 },
    { duration: '8s', target: 100 },
    { duration: '3s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  group('Web Shells', () => {
    const res = http.get(`${BASE_URL}/`);
    webAppTrend.add(res.timings.duration);
    check(res, { 'root web 200': (r) => r.status === 200 });

    const appRes = http.get(`${BASE_URL}/app`);
    check(appRes, { 'e2e shell 200': (r) => r.status === 200 });
  });

  group('Public Feed & Ads Read', () => {
    const home = http.get(`${BASE_URL}/api/v1/home`);
    homeTrend.add(home.timings.duration);
    check(home, { 'home 200': (r) => r.status === 200 });

    const tax = http.get(`${BASE_URL}/api/v1/taxonomy`);
    check(tax, { 'taxonomy 200': (r) => r.status === 200 });

    const ads = http.get(`${BASE_URL}/api/v1/ads?category_id=1&city_id=1`);
    adsListTrend.add(ads.timings.duration);
    check(ads, { 'ads list 200': (r) => r.status === 200 });

    const detail = http.get(`${BASE_URL}/api/v1/ads/1`);
    adDetailTrend.add(detail.timings.duration);
    check(detail, { 'ad detail 200': (r) => r.status === 200 });
  });

  group('Authenticated Write Flow', () => {
    const loginRes = http.post(
      `${BASE_URL}/api/v1/auth/login`,
      JSON.stringify({ login: 'seller@apolo.ma', password: 'Password123!' }),
      { headers: { 'Content-Type': 'application/json' } }
    );
    loginTrend.add(loginRes.timings.duration);
    check(loginRes, { 'login 200': (r) => r.status === 200 });

    const body = loginRes.json();
    const token = body && body.token;
    if (token) {
      const adRes = http.post(
        `${BASE_URL}/api/v1/ads`,
        JSON.stringify({
          title: `إعلان ضغط #${__VU}-${__ITER}`,
          description: 'اختبار ضغط الأداء تحت حمل متزايد',
          price: 2500,
          category_id: 3,
          city_id: 1,
          phone_call: '0612345678',
        }),
        {
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
        }
      );
      createAdTrend.add(adRes.timings.duration);
      check(adRes, { 'create ad 201': (r) => r.status === 201 });
    }
  });

  sleep(0.2);
}
