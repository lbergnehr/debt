
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
		# New participant
		"click button" : (event) -> 
			Participants.insert name: $("#participant-name")[0].value, eventId	: Session.get "eventId"
			false

		# Remove participant
		"click .icon-trash" : (event) -> Participants.remove this

		# Edit participant name
		"dblclick span"	: (event) ->
			editable = $(event.srcElement.parentNode)
			editable.addClass "editing"
			editable.find("input").focus()

		"blur input"	: (event) -> exitEditMode this, event
		"keypress input": (event) -> exitEditMode this, event if event.keyCode == 13 # enter

		# Drag and drop between participants
		"dragstart .participant": (event) -> dragSource = this
		"dragover .participant"	: (event) ->
			event.srcElement.classList.add "drag-over" unless this == dragSource
		"dragleave .participant": (event) ->
			event.srcElement.classList.remove "drag-over" unless this == dragSource 

	exitEditMode = (context, event) ->
		Participants.update {_id: context._id}, {$set: {name: event.srcElement.value}}
		$(event.srcElement.parentNode.parentNode).removeClass "editing"


