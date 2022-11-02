# frozen_string_literal: true

require 'rainbow'
require 'yaml'
require 'diffy'
require 'ruby-progressbar'
require 'contentful/management'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/module/delegation'

require_relative "discontentful/version"
require_relative "discontentful/rich_text"
require_relative "discontentful/stats"
require_relative "discontentful/contentful_updater"
require_relative "discontentful/transformation"

module Discontentful
  class Error < StandardError; end

end
