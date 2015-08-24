RSpec.describe Doctor::Proxy::Base do
  describe '#initialize' do
    it 'sets target, old_method and tags' do
      old_method = method(:puts)
      base = Doctor::Proxy::Base.new(1, old_method, [])
      expect(base.instance_eval { @target }).to be(1)
      expect(base.instance_eval { @old_method }).to be(old_method)
      expect(base.instance_eval { @tags }).to eq([])
    end
  end
end
