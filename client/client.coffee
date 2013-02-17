Session.set "eventId" -1
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

# Event template
Template.event.event = () -> 
	Events.findOne {_id : Session.get "eventId"}, {name : 1}

Template.event.debts = () ->
	Debts.find {eventId : Session.get "eventId"}

saveDebt = (id, name, amount) ->
	Debts.update({_id : id, $set : {name : name, amount : amount}})

Template.event.events =
	# # Remove debt
	# "click .remove-participant" : (event) -> 
	# 	console.log "removing participant #{this.name}."
	# 	removeParticipant this

	# Edit participant name
	"dblclick span.hide-on-edit" : (event) ->
		editable = $(event.srcElement.parentNode)
		editable.addClass "editing"
		editable.find("input").focus()

	"blur .edit input" : (event) -> saveDebt this._id, this.name, this.amount

	"keypress .edit input" : (event) -> saveDebt this, this.name, this.amount if event.keyCode == 13 # enter

Template.main.isHome = () ->
	eventId = Session.get "eventId";
	eventId == null || eventId == ""

Template.home.events = 
	"keyup input"	: (event) ->
		textBoxValue = $("input")[0].value
		$("button").attr "disabled",
			(textBoxValue == null || textBoxValue.trim() == "") ? "disabled" : null

	"click button"	: (event) -> 
		textBoxValue = $("input")[0].value
		if textBoxValue
			newId = Events.insert {name: textBoxValue}
			@app.navigate newId, true
		false

Template.participants.rendered = () ->
	console.log "participants rendered"
	self = this

	Meteor.autorun () ->
		participantData = Participants.find({eventId : Session.get "eventId"}).fetch()

		container = $(".participant-group")
		width = container.width()
		height = width
		container.height(width)
		radius = Math.min(width, height) * 0.4
		nItems = participantData.length
		angleIncrease = 2 * Math.PI / nItems

		console.log "#{width}, #{height}"

		# The selection to work on
		participants = d3
			.select(".participant-group")
			.selectAll(".participant")
			.data(participantData, (d) -> d._id)

		# Create an element
		participants.enter().append("div")
			.classed("participant", true)
			.each (d, i) ->
				el = d3.select this
				el.html Template.participant({name : d.name})

		participants
			.transition()
				.duration(250)
				.attr "style", (d, i) ->
					el = $(this)
					x = radius * Math.cos(angleIncrease * i) + width / 2 - el.width() / 2
					y = radius * Math.sin(angleIncrease * i) + height / 2 - el.height() / 2
					"left:#{x}px; top:#{y}px"

dragSource = null
Template.participants.events = 
	# New participant
	"click button" : (event) -> 
		event.preventDefault()
		nameTextBox = $("#participant-name")[0]
		emailTextBox = $("#participant-email")[0]
		addParticipant nameTextBox.value, emailTextBox.value
		nameTextBox.value = null
		emailTextBox.value = null

	# Drag and drop between participants
	"dragstart .participant": (event) -> dragSource = this
	"dragover .participant"	: (event) ->
		event.srcElement.classList.add "drag-over" unless this == dragSource
		event.preventDefault()
		false
	"dragleave .participant": (event) ->
		event.srcElement.classList.remove "drag-over" unless this == dragSource 
	"drop .participant"		: (event) -> 
		unless this == dragSource
			console.log event
			event.srcElement.classList.remove "drag-over"
			addDebt dragSource, this, event.target

removeParticipant = (participant) -> Participants.remove participant

exitEditMode = (context, event) ->
	Participants.update {_id: context._id}, {$set: {name: event.srcElement.value}}
	$(event.srcElement.parentNode.parentNode).removeClass "editing"

renderParticipants = () ->
	console.log "rendering participants"

addParticipant = (name, email) ->
	console.log "adding participant"
	Meteor.call "addParticipant", {eventId : Session.get("eventId"), name : name, email : email}, (ret) ->
		console.log "adding done: #{ret}"











