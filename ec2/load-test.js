
import http from 'k6/http';
import { check } from 'k6';
import { Counter } from 'k6/metrics';

// Custom metrics
const getRequests = new Counter('get_requests_total');
const getPassed = new Counter('get_requests_passed');
const getFailed = new Counter('get_requests_failed');

const postRequests = new Counter('post_requests_total');
const postPassed = new Counter('post_requests_passed');
const postFailed = new Counter('post_requests_failed');

export const options = {
  stages: [
    { duration: '10s', target: 1000 },
    { duration: '3m', target: 1000 },
    { duration: '10s', target: 5000 },
    { duration: '5m', target: 5000 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
  },
};

const BASE_URL =
  'http://web-scaling-1-1968462550.us-east-1.elb.amazonaws.com';

export default function () {
  // GET homepage
  getRequests.add(1);

  const homeResponse = http.get(BASE_URL, {
    timeout: '15s',
  });

  const getOk = check(homeResponse, {
    'homepage status 200': (r) => r.status === 200,
  });

  if (getOk) {
    getPassed.add(1);
  } else {
    getFailed.add(1);
    return;
  }

  // Extract Rails CSRF token
  const csrfToken = homeResponse
    .html()
    .find('meta[name="csrf-token"]')
    .attr('content');

  if (!csrfToken) {
    console.error('CSRF token missing');
    postRequests.add(1);
    postFailed.add(1);
    return;
  }

  // POST create Todo
  postRequests.add(1);

  const payload = {
    authenticity_token: csrfToken,
    'todo[title]': `Load Test VU-${__VU}-${__ITER}`,
    'todo[details]': 'Created by k6 load testing',
    'todo[due_date]': '',
    button: '',
  };

  const response = http.post(
    `${BASE_URL}/todos`,
    payload,
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      redirects: 0,
      timeout: '15s',
    }
  );

  const postOk = check(response, {
    'todo created (redirect)': (r) =>
      r.status === 302 || r.status === 303,
  });

  if (postOk) {
    postPassed.add(1);
  } else {
    postFailed.add(1);
  }
}
