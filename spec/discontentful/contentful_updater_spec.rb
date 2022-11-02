# frozen_string_literal: true

RSpec.describe Discontentful::ContentfulUpdater do
  describe '#update_entry' do
    let(:entry) do
      double(
        Contentful::Management::DynamicEntry,
        sys: {contentType: double(id: 'thing') },
        id: 'id',
        published?: true,
        publish: nil,
        update: nil,
        field1: 'val1',
        field2: 'val2',
        field3: { a: 1, b: 2 }
      )
    end
    let(:environment) { double(Contentful::Management::Environment) }
    let(:stats) { Discontentful::Stats.new }

    it 'doesn\'t update the fields when dry run is specified' do
      updater = described_class.new(stats, environment, true, true)
      expect(entry).not_to receive(:update)
      updater.update_entry(entry, field1: 'val3', field2: 'val4')
    end

    it 'updates only the changed fields' do
      updater = described_class.new(stats, environment, false, true)
      expect(entry).to receive(:update).with(field1: 'val3', field3: { a: 1, b: 3 })
      updater.update_entry(entry, field1: 'val3', field2: 'val2', field3: { a: 1, b: 3 })
    end

    it 'does not publish the record if republish is false' do
      updater = described_class.new(stats, environment, false, false)
      expect(entry).not_to receive(:publish)
      updater.update_entry(entry, field1: 'val3', field2: 'val2', field3: { a: 1, b: 3 })
    end

    it 'publishes the record if republish is true and the record was published' do
      updater = described_class.new(stats, environment, false, true)
      expect(entry).to receive(:publish)
      updater.update_entry(entry, field1: 'val3', field2: 'val2', field3: { a: 1, b: 3 })
    end

    it 'does not publish the record if republish is true and the record was not published' do
      updater = described_class.new(stats, environment, false, true)
      allow(entry).to receive(:published?).and_return(false)
      expect(entry).to_not receive(:publish)
      updater.update_entry(entry, field1: 'val3', field2: 'val2', field3: { a: 1, b: 3 })
    end
  end
end