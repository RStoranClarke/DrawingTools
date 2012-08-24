require('lib/setup')

Spine = require('spine')

HomeConroller 	= 	require('controllers/homeController')
Classifier 		= 	require('controllers/Classifier')
MarkingSurface 	= 	require('controllers/MarkingSurface')
Marker 			= 	require('controllers/Marker')

Api 			=  	require('zooniverse/lib/api')
Config 			= 	require('lib/config')
TopBar 			=   require('zooniverse/lib/controllers/top_bar')

class App extends Spine.Controller
  constructor: ->
    super
    Api.init host: Config.apiHost
    @append new HomeConroller()
	    
    @classify = new Classifier()
    topBar = new TopBar
    	el: '.zooniverse-top-bar'
    	languages:
    		en : "English"
   
    @append @classify
    @classify.el.hide()

    Spine.bind "showClassificaitonInterface", =>
      @classify.el.fadeIn 200


module.exports = App
    