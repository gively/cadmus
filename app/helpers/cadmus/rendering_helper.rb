module Cadmus::RenderingHelper
  def render_cadmus_page_in_effective_layout(page)
    page_content = cadmus_renderer.render(@page.liquid_template, :html)
    cms_layout = @page.effective_cms_layout
    render_in_cadmus_layout(page_content, cms_layout, 'page' => page)
  end

  def render_in_cadmus_layout(content, cms_layout, assigns = {})
    if cms_layout
      assigns = assigns.merge({ 'content_for_layout' => content })
      if defined?(:liquid_assigns_for_layout)
        assigns.reverse_merge!(liquid_assigns_for_layout(cms_layout))
      end

      cadmus_renderer.render(cms_layout.liquid_template, :html, assigns: assigns)
    else
      content_for :content do
        content
      end

      render template: 'layouts/application'
    end
  end
end
