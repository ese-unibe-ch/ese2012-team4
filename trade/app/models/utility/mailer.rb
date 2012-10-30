module Models

  # Sends Mails
  # Uses the g-mail Address tradingsystem.mail@gmail.com to do this.
  # Do not send private mails to this address, since its password is visible here and therefore visible online as well.
  class Mailer

    # Sends an e-mail
    # - @param [String] to: e-mail address of the receiver of this mail
    # - @param [String] contents: Content in the mail, without signature and greetings, which is added automatically.
    def self.send_mail_to(to,contents)
    require 'rubygems'
    require 'tlsmail'
    require 'time'
    from = 'tradingsystem.mail@gmail.com'
    pw = 'trade1234'

    content = <<EOF
From: #{from}
To: #{to}
subject: Your Item has been sold!
Date: #{Time.now.rfc2822}

    #{contents}

Regards,
The Trading System
EOF

    Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
    Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', from, pw, :login) do |smtp|
      smtp.send_message(content, from, to)
    end
  end
  end
end