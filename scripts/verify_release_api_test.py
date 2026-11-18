import unittest
from verify_release_api import validate_health, validate_catalog

class Contract(unittest.TestCase):
    def test_existing_server_can_serve_new_client_without_version_equality(self):
        validate_health({'status':'ok','version':'4.0.2'})
        validate_catalog({'status':'success','data':[]})
    def test_unknown_or_incompatible_server_cannot_publish(self):
        for body in [{'status':'ok','version':'0.0.0'}, {'status':'error','version':'4.0.2'}]:
            with self.assertRaises(AssertionError): validate_health(body)
        for body in [{'status':'success','data':{}},{'status':'error','data':[]}]:
            with self.assertRaises(AssertionError): validate_catalog(body)

if __name__=='__main__':unittest.main()
