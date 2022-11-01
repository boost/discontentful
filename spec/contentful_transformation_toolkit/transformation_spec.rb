# frozen_string_literal: true

RSpec.describe ContentfulTransformationToolkit::Transformation do

  let(:environment) { double(Contentful::Management::Environment, entries: entries) }

  let(:entries) do
    entries = double(
      Contentful::Management::EnvironmentEntryMethodsFactory
    )
    array = Contentful::Management::Array.new
    array.items = records
    array.total = records.count
    allow(entries).to receive(:all).with(content_type: 'page', limit: 100).and_return(array)
    entries
  end

  let(:records) do
    [
      double(Contentful::Management::Entry),
      double(Contentful::Management::Entry),
      double(Contentful::Management::Entry),
    ]
  end

  describe '#run' do
    let(:simple) do
      Class.new(ContentfulTransformationToolkit::Transformation) do
        source_content_model 'page'

        def each(page)

        end
      end
    end

    subject { simple.new(environment) }

    it 'tells us how many items it has found' do
      expect{ subject.run }.to output(/Found 3 page entries/).to_stdout
    end

    it 'calls #each with each entry in source content model' do
      expect(subject).to receive(:each).with(records[0]).once
      expect(subject).to receive(:each).with(records[1]).once
      expect(subject).to receive(:each).with(records[2]).once
      subject.run
    end

    context 'when there are multiple pages' do
      let(:entries) do
        entries = double(
          Contentful::Management::EnvironmentEntryMethodsFactory
        )
        page1 = Contentful::Management::Array.new
        page1.items = records[0..1]
        page1.total = records.count
        page2 = Contentful::Management::Array.new
        page2.items = records[2..]
        page2.total = records.count
        page2.skip = 2
        allow(page1).to receive(:next_page).and_return(page2)
        allow(entries).to receive(:all).with(content_type: 'page', limit: 100).and_return(page1)
        entries
      end

      it 'calls #each with each entry in source content model' do
        expect(subject).to receive(:each).with(records[0]).once
        expect(subject).to receive(:each).with(records[1]).once
        expect(subject).to receive(:each).with(records[2]).once
        subject.run
      end
    end

    context 'when an error or warning is called within the each method' do
      let(:records) do
        [
          double(Contentful::Management::Entry, id: 'record-id'),
        ]
      end

      let(:simple) do
        Class.new(ContentfulTransformationToolkit::Transformation) do
          source_content_model 'page'

          def each(page)
            error("oh dear")
            warning("hmm")
            info('ok')
          end
        end
      end

      it 'outputs the current record with the message' do
        expect{ subject.run }.to output(/Error: \[record-id\] oh dear/).to_stdout
        expect{ subject.run }.to output(/Warning: \[record-id\] hmm/).to_stdout
        expect{ subject.run }.to output(/Info: \[record-id\] ok/).to_stdout
      end
    end
  end
end
