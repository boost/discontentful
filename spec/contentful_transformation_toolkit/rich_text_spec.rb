# frozen_string_literal: true

RSpec.describe ContentfulTransformationToolkit::RichText do
  let(:example_rich_text) do
    {
      "data"=>{},
      "content"=>[
        {"data"=>{},
          "content"=>
          [{"data"=>{},
            "marks"=>[],
            "value"=>
              "Some text ",
            "nodeType"=>"text"}],
          "nodeType"=>"paragraph"},
        {"data"=>{},
          "content"=>[
            {
              "data"=>{},
              "marks"=>[],
              "value"=>"Some other text",
              "nodeType"=>"text"
            }
          ],
          "nodeType"=>"paragraph"
        },
        {"data"=>{}, "content"=>[{"data"=>{}, "marks"=>[], "value"=>"Contact us", "nodeType"=>"text"}], "nodeType"=>"heading-2"},
        {"data"=>{}, "content"=>[{"data"=>{}, "marks"=>[], "value"=>"Another heading", "nodeType"=>"text"}], "nodeType"=>"heading-2"},
        {
          "data"=>{},
          "content"=>[
            {"data"=>{}, "marks"=>[{"type"=>"bold"}], "value"=>"Stay in touch and keep up-to-date", "nodeType"=>"text"}
          ],
          "nodeType"=>"paragraph"
        },
      ],
      "nodeType"=>"document"
    }
  end

  subject { described_class.new(example_rich_text) }

  describe '#replace_nodes' do
    it 'visits all nodes with a matching node type' do
      expect { |b| subject.replace_nodes(node_type: 'text', &b) }.to yield_successive_args(
        {"data"=>{}, "marks"=>[], "value"=> "Some text ", "nodeType"=>"text"},
        {"data"=>{}, "marks"=>[], "value"=>"Some other text", "nodeType"=>"text"},
        {"data"=>{}, "marks"=>[], "value"=>"Contact us", "nodeType"=>"text"},
        {"data"=>{}, "marks"=>[], "value"=>"Another heading", "nodeType"=>"text"},
        {"data"=>{}, "marks"=>[{"type"=>"bold"}], "value"=>"Stay in touch and keep up-to-date", "nodeType"=>"text"}
      )
    end

    it 'replaces the node with the return value' do
      replaced_text = subject.replace_nodes(node_type: 'heading-2') do |node|
        {
          "data"=>{},
          "content"=>node["content"],
          "nodeType"=>"heading-3"
        }
      end
      expect(replaced_text["content"]).to include(
        {"data"=>{}, "content"=>[{"data"=>{}, "marks"=>[], "value"=>"Contact us", "nodeType"=>"text"}], "nodeType"=>"heading-3"},
        {"data"=>{}, "content"=>[{"data"=>{}, "marks"=>[], "value"=>"Another heading", "nodeType"=>"text"}], "nodeType"=>"heading-3"}
      )
    end
  end

  describe '#find_ndoes' do
    it 'visits all nodes with a matching node type' do
      expect { |b| subject.find_nodes(node_type: 'text', &b) }.to yield_successive_args(
        {"data"=>{}, "marks"=>[], "value"=> "Some text ", "nodeType"=>"text"},
        {"data"=>{}, "marks"=>[], "value"=>"Some other text", "nodeType"=>"text"},
        {"data"=>{}, "marks"=>[], "value"=>"Contact us", "nodeType"=>"text"},
        {"data"=>{}, "marks"=>[], "value"=>"Another heading", "nodeType"=>"text"},
        {"data"=>{}, "marks"=>[{"type"=>"bold"}], "value"=>"Stay in touch and keep up-to-date", "nodeType"=>"text"}
      )
    end

    it 'doesn\'t update nodes with a matching node type' do
      replaced_text = subject.find_nodes(node_type: 'heading-2') do |node|
        {
          "data"=>{},
          "content"=>node["content"],
          "nodeType"=>"heading-3"
        }
      end
      expect(replaced_text).to eq example_rich_text
    end
  end
end