module Discontentful
  class RichText
    def initialize(rich_text)
      @rich_text = rich_text.deep_dup
    end

    def replace_nodes(node_type:, &block)
      map_nodes do |node|
        if node["nodeType"] == node_type
          (yield node) || node
        else
          node
        end
      end
    end

    def find_nodes(node_type: nil, &block)
      map_nodes do |node|
        if node["nodeType"] == node_type
          yield node
        end
        node
      end
    end

    private

    def map_nodes(&block)
      return if @rich_text.nil?

      map_node(@rich_text, &block)
    end

    def map_node(node, &block)
      new_node = yield node
      return if new_node.nil?

      new_content = map_content(new_node, &block)
      new_node["content"] = new_content unless new_content.nil?

      new_node
    end

    def map_content(node, &block)
      return if node["content"].nil?

      node["content"].map do |content_node|
        map_node(content_node, &block)
      end.compact
    end
  end
end