require 'test_helper'
require 'webmock/minitest'
require 'sensu-handler'

class TestHandleAPIRequest < MiniTest::Test
  include SensuPluginTestHelper

  Sensu::Handler.disable_autorun

  def sample_check_result
    {
      client: 'sensu',
      check: {
        handler: 'keepalive',
        name: 'keepalive',
        issued: 1_534_373_016,
        executed: 1_534_373_016,
        output: 'Keepalive sent from client 4 seconds ago',
        status: 0,
        type: 'standard',
        history: [0]
      }
    }
  end

  def test_http_request
    stub_request(:get, 'http://127.0.0.1:4567/foo').to_return(status: 200, body: '', headers: {})

    handler = Sensu::Handler.new([])
    response = handler.api_request(:get, '/foo')

    assert_equal(response.code, '200')
  end

  def test_http_paginated_get
    stub_request(:get, 'http://127.0.0.1:4567/results?limit=50&offset=0')
      .to_return(status: 200, headers: {}, body: JSON.dump([sample_check_result]))

    stub_request(:get, 'http://127.0.0.1:4567/results?limit=50&offset=50')
      .to_return(status: 200, headers: {}, body: JSON.dump([]))

    handler = Sensu::Handler.new([])
    response = handler.paginated_get('/results', 'limit' => 50)
    assert_equal(response, [sample_check_result])
  end

  def test_https_request
    stub_request(:get, 'https://127.0.0.1:4567/foo').to_return(status: 200, body: '', headers: {})

    handler = Sensu::Handler.new([])
    handler.api_settings = handler.api_settings.merge('ssl' => {})

    response = handler.api_request(:get, '/foo')

    assert_equal(response.code, '200')
  end
end
