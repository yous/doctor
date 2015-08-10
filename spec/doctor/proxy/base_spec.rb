RSpec.describe Doctor::Proxy::Base do
  describe '#initialize' do
    it 'sets target and tags' do
      base = Doctor::Proxy::Base.new(1, [])
      expect(base.instance_variable_get(:@target)).to be(1)
      expect(base.instance_variable_get(:@tags)).to eq([])
    end
  end
end