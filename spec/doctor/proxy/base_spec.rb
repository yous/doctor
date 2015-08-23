RSpec.describe Doctor::Proxy::Base do
  describe '#initialize' do
    it 'sets target, old_method and tags' do
      old_method = method(:puts)
      base = Doctor::Proxy::Base.new(1, old_method, [])
      expect(base.instance_variable_get(:@target)).to be(1)
      expect(base.instance_variable_get(:@old_method)).to be(old_method)
      expect(base.instance_variable_get(:@tags)).to eq([])
    end
  end
end
