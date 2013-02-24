
Events = new Meteor.Collection "Event"
Participants = new Meteor.Collection "Participants"
Debts = new Meteor.Collection "Borrowings"

Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1