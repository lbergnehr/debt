
Events = new Meteor.Collection "Event"
Participants = new Meteor.Collection "Participants"

if Meteor.isClient
	# Set up Backbone router
	Router = Backbone.Router.extend
		routes:
			""			: "home"
			"*eventId"	: "loadEvent"

		home: () -> Session.set "eventId", null

		loadEvent: (eventId) ->
			Session.set "eventId", eventId
			false

	@app = new Router
	Backbone.history.start {pushState: true}

	Template.event.event = () -> 
		Events.findOne {_id : Session.get "eventId"}, {name : 1}

	Template.main.isHome = () ->
		eventId = Session.get "eventId";
		eventId == null || eventId == ""

	Template.home.events = 
		"keyup input"	: (event) ->
			textBoxValue = $("input")[0].value
			$("button").attr "disabled", (textBoxValue == null || textBoxValue == "") ? "disabled" : null

		"click button"	: (event) -> 
			textBoxValue = $("input")[0].value
			if textBoxValue
				newId = Events.insert {name: textBoxValue}
				@app.navigate newId, true
			false

	Template.participants.participants = () ->
		Participants.find {eventId: Session.get "eventId"}

	dragSource = null
	Template.participants.events = 
		"click button" : (event) -> 
			Participants.insert name: $("#participant-name")[0].value, eventId	: Session.get "eventId"
			false

		"dragstart .participant"	: (event) ->
			dragSource = this

		"dragover .participant" 	: (event) ->
			return if this == dragSource
			event.srcElement.classList.add("drag-over")

		"dragleave .participant"	: (event) ->
			return if this == dragSource
			event.srcElement.classList.remove("drag-over")
