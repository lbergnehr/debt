

Meteor.startup () ->
	console.log "started..."

Meteor.methods 
	"addParticipant" : (args) ->
		@crypto = __meteor_bootstrap__.require "crypto"

		eventId = args.eventId
		name = args.name
		email = args.email

		email = email.toLowerCase() if email?
		hash = @crypto.createHash('md5').update(email).digest("hex") if email?

		console.log "creating participant: eventId: #{eventId}, name: #{name}, email: #{email}, hash: #{hash}"

		id = Participants.insert
			eventId : eventId
			name : name
			email : email
			hash : hash

		console.log "inserted id: #{id}"
		id
