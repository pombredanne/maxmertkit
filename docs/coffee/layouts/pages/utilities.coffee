CollectionViewMenu = require( '../../collectionviews/sidebar/menu' ).module
CollectionViewContent = require( '../../collectionviews/content' ).module

ViewSocial = require( '../../views/pages/social' )


exports.module = Marionette.Layout.extend

    model: new Backbone.Model kit

    template: $.app.templates.common.pages.utilities

    regions:
        sidebar: '#sidebar'
        content: '#content'

        socialContribute: '#social-contribute'


    onRender: ->

        @sidebar.show new CollectionViewMenu()
        @content.show new CollectionViewContent()
        @socialContribute.show new ViewSocial.github()
        setTimeout =>
            @sidebar.currentView.$el[0].affix( offset: -25 )
        , 1
        $.app.commands.execute 'menu', 'activate', '#utilities'
        $.app.commands.execute 'loader', 'finish'
