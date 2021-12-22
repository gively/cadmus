require 'rails-html-sanitizer'

module Cadmus

  # A Cadmus renderer is an object that handles the rendering of +Liquid::Template+s to output formats
  # such as HTML or plain text.  A renderer provides several features over and above what plain
  # Liquid does:
  #
  # * Automatic removal of HTML tags for plain text output
  # * Integration with Rails 3's HTML escaping functionality
  # * Ability to specify default assigns, filters, and registers and augment them on a per-call basis
  # * Ability to render to multiple output formats from a single renderer
  module Renderers

    # The simplest Cadmus renderer.  It will render Liquid templates to HTML and plain text (removing the
    # HTML tags from the plain text output).
    class Base
      attr_accessor :default_assigns, :default_filters, :default_registers, :html_sanitizer

      DEFAULT_HTML_SANITIZER = Rails::Html::FullSanitizer

      def initialize
        self.default_registers = {}
        self.default_filters = []
        self.default_assigns = {}

        self.html_sanitizer = Rails.application.config.action_view.full_sanitizer || DEFAULT_HTML_SANITIZER.new
      end

      # The preprocess method performs the initial rendering of the Liquid template using the a combination
      # of the default_filters, default_assigns, default_registers, and any :assigns, :filters, and :registers
      # options passed in as options.
      #
      # @param [Liquid::Template] template the Liquid template to render.
      # @param [Symbol] format the format being used for rendering.  (This is ignored in the Base implementation
      #   of +preprocess+ and is only used in Base's +render+ method, but is passed here in case subclasses wish to
      #   make use of the format information when overriding preprocess.)
      # @param [Hash] options additional options that can be passed to override default rendering behavior.
      # @option options [Hash] :assigns additional assign variables that will be made available to the template.
      # @option options [Hash] :registers additional register variables that will be made available to the template.
      # @option options [Hash] :filters additional filters to be made available to the template.
      # @return [String] the raw results of rendering the Liquid template.
      def preprocess(template, format, options={})
        render_args = [
          default_assigns.merge(options[:assigns] || {}),
          {
            :filters   => default_filters + (options[:filters] || []),
            :registers => default_registers.merge(options[:registers] || {})
          }
        ]

        template.render(*render_args)
      end

      # Render a given Liquid template to the specified format.  This renderer implementation supports +:html+ and
      # +:text+ formats, but other implementations may support other formats.
      #
      # @param [Liquid::Template] template the Liquid template to render.
      # @param [Symbol] format the format being used for rendering.  +:html+ will result in a string that's marked
      #   as safe for HTML rendering (and thus won't be escaped by Rails).  +:text+ will strip all HTML tags out
      #   of the template result.
      # @param [Hash] options additional rendering options.  See the +preprocess+ method for a description of
      #   available options.
      def render(template, format, options={})
        content = preprocess(template, format, options)

        case format.to_sym
        when :html
          content.html_safe
        when :text
          html_sanitizer.sanitize content
        else
          raise "Format #{format.inspect} unsupported by #{self.class.name}"
        end
      end
    end
  end

  # A helper module that can be included in classes that wish to provide a Cadmus renderer.  For
  # example, an Email class might want to provide a renderer so that it can be easily transformed
  # into HTML or text formats.
  #
  # This will expose a +cadmus_renderer+ method that constructs a new renderer.  Optionally, you
  # can implement methods called +liquid_assigns+, +liquid_registers+, and +liquid_filters+, which
  # will specify the default assigns, registers, and filters for the renderer.  You can also
  # override the +cadmus_renderer_class+ method if you want to use a renderer class aside from
  # Cadmus::Renderers::Base.
  #
  # == Example
  #
  #     class Email < ActiveRecord::Base
  #       include Cadmus::Renderable
  #
  #       def liquid_template
  #         Liquid::Template.new(self.content)
  #       end
  #
  #       def liquid_assigns
  #         { recipient: self.recipient, sender: self.sender, sent_at: self.sent_at }
  #       end
  #     end
  module Renderable

    # @return a new Cadmus renderer set up using the +default_assigns+, +default_registers+
    #   and +default_filters+ methods, if they exist.
    def cadmus_renderer
      cadmus_renderer_class.new.tap { |renderer| setup_renderer(renderer) }
    end

    # @return the Cadmus renderer class to instanciate in the +cadmus_renderer+ method.  By
    #   default, Cadmus::Renderers::Base.
    def cadmus_renderer_class
      Cadmus::Renderers::Base
    end

    protected
    # Sets the values of +default_assigns+, +default_registers+ and +default_filters+ on a given
    # renderer using the +liquid_assigns+, +liquid_registers+ and +liquid_filters+ methods, if
    # they're defined.
    def setup_renderer(renderer)
      renderer.default_assigns = liquid_assigns if respond_to?(:liquid_assigns, true)
      renderer.default_registers = liquid_registers if respond_to?(:liquid_registers, true)
      renderer.default_filters = liquid_filters if respond_to?(:liquid_filters, true)
    end
  end
end
