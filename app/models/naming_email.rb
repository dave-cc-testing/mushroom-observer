# Class for holding code specific to QueuedEmails intended to send email_naming emails.
#
# The separation is nice, but it kind of violates some of Rails assumptions.  In particular,
# the initialize if dangerous since it does saves.  However, I can't figure out a way to
# get these out of the database so as long the creation is explicit in code things should
# be fine.
class NamingEmail < QueuedEmail
  def self.create_email(notification, naming)
    sender = notification.user
    observer = naming.observation.user
    result = nil
    if sender != observer
      result = NamingEmail.new()
      result.setup(sender, observer, :naming)
      result.save()
      result.add_integer(:naming, naming.id)
      result.add_integer(:notification, notification.id)
      result.finish()
    end
    result
  end
  
  # While this looks like it could be an instance method, it has to be a class
  # method for QueuedEmails that come out of the database to work.  See queued_emails.rb
  # for more details.
  def deliver_email
    naming = nil
    notification = nil
    (naming_id, notification_id) = get_integers([:naming, :notification])
    naming = Naming.find(naming_id) if naming_id
    notification = Notification.find(notification_id) if notification_id
    if naming
      if user != to_user
        AccountMailer.deliver_naming_for_tracker(user, naming)
        if notification && notification.note_template
          AccountMailer.deliver_naming_for_observer(to_user, naming, notification)
        end
      else
        print "Skipping email with same sender and recipient, #{user.email}\n" if !TESTING
      end
    else
      print "No naming found (#{self.id})\n"
    end
  end
end
