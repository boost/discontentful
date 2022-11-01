# frozen_string_literal: true

require 'rainbow'
require 'yaml'
require 'diffy'
require 'ruby-progressbar'
require 'contentful/management'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/deep_dup'

require_relative "contentful_transformation_toolkit/version"
require_relative "contentful_transformation_toolkit/rich_text"
require_relative "contentful_transformation_toolkit/transformation"

module ContentfulTransformationToolkit
  class Error < StandardError; end

end
