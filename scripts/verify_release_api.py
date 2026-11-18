"""Verify the client's supported API contract independently of product version."""
import json
import sys
import urllib.parse
import urllib.request


def validate_health(body):
    assert isinstance(body, dict) and body.get('status') == 'ok', 'API is unhealthy'
    assert body.get('version') in {'4.0.2', '5.2.0'}, 'Unreviewed API version'


def validate_catalog(body):
    assert isinstance(body, dict) and body.get('status') == 'success', 'Catalog request failed'
    assert isinstance(body.get('data'), list), 'Missing catalog data contract'


def verify(base):
    url = urllib.parse.urlsplit(base)
    assert url.scheme == 'https' and url.hostname and not url.username and not url.password
    assert not url.query and not url.fragment and url.path in ('', '/')
    def get(path):
        with urllib.request.urlopen(base.rstrip('/') + path, timeout=90) as response:
            assert response.status == 200
            value = response.read(1024 * 1024 + 1)
            assert len(value) <= 1024 * 1024, 'Oversized API response'
            return json.loads(value)
    health = get('/health')
    validate_health(health)
    for path in ['/api/v1/live/groups', '/api/v1/catalog?ref=catalog%3Amovie%3Aall&page=1']:
        validate_catalog(get(path))
    return {'compatible': True, 'api_version': health['version'], 'client_version': '5.2.0'}


if __name__ == '__main__':
    print(json.dumps(verify(sys.argv[1])))
