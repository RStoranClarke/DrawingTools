Spine = require('spine')

class HomeController extends Spine.Controller
  className: 'NavController'
  
  elements:
    'div.right' : 'content'
    '.nav li'   : 'navLinks'

  events:
    'click .nav li' : 'navigate'

  constructor: ->
    super
    @render()

  render:()=>

    @html require("views/nav")
    @renderContent('about')
  
  renderContent:(section='team')=>
    @content.fadeOut 400, =>
      @content.html require("views/#{section}")
      @content.css("display","none")
      @content.fadeIn 400

  navigate:(e)=>
    e.preventDefault()
    section = $(e.currentTarget).data().section
    
    if section=='classify'
      @el.fadeOut 200,=>
        Spine.trigger("showClassificaitonInterface")
    else
      @navLinks.removeClass("active")
      $(e.currentTarget).addClass("active")
      @renderContent(section)

module.exports = HomeController