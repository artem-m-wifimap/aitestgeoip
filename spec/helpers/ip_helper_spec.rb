# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IPHelper do
  let(:helper) { Class.new { include IPHelper }.new }

  describe '#request_ip' do
    context 'when X-Forwarded-For header is present' do
      it 'returns the first IP from X-Forwarded-For' do
        env = { 'HTTP_X_FORWARDED_FOR' => '203.0.113.1, 198.51.100.2' }
        allow(helper).to receive(:env).and_return(env)
        expect(helper.request_ip).to eq('203.0.113.1')
      end
    end

    context 'when X-Forwarded-For header is not present' do
      it 'returns the REMOTE_ADDR' do
        env = { 'REMOTE_ADDR' => '192.0.2.1' }
        allow(helper).to receive(:env).and_return(env)
        expect(helper.request_ip).to eq('192.0.2.1')
      end
    end
  end
end
