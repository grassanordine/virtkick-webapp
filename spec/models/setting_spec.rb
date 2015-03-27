describe Setting do
  context 'development environment' do
    before do
      Rails.env = 'development'
    end

    after do
      Rails.env = 'test'
    end

    it 'allows persistent setting' do
      Setting.set 'key', 'new_val_1', temporary: false
      expect(Setting.get 'key').to eq 'new_val_1'
    end

    it 'allows temporary setting' do
      Setting.set 'key', 'new_val_2', temporary: true
      expect(Setting.get 'key').to eq 'new_val_2'
    end
  end

  context 'production environment' do
    before do
      Rails.env = 'production'
    end

    after do
      Rails.env = 'test'
    end

    it 'allows persistent setting' do
      Setting.set 'key', 'new_val_3', temporary: false
      expect(Setting.get 'key').to eq 'new_val_3'
    end

    it 'forbids temporary variable' do
      expect { Setting.set 'key', 'new_val_4', temporary: true }.to raise_exception
      expect(Setting.get 'key').not_to eq 'new_val_4'
    end
  end
end
