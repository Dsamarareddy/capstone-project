from service.app import create_app


def test_health_returns_ok():
    res = create_app().test_client().get("/health")
    assert res.status_code == 200
    assert res.json["service"] == "TODO-service-name"
