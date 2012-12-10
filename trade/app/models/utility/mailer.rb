module Models

  # Sends Mails
  # Uses the web.de-Address trading.mail@web.de to do this.
  # Do not send private mails to this address, since its password is visible here and therefore visible online as well.
  class Mailer

    # Sends an e-mail
    # - @param [String] to: e-mail address of the receiver of this mail
    # - @param [String] contents: Content in the mail, without signature and greetings, which is added automatically.
    def self.item_sold(to, contents)
      self.send_mail("trading.mail@web.de", to, "Your Item has been sold!", contents)
    end

    def self.item_bought(to, item , user)
      body = Content.new(:value => "You have bought the item #{item.name} from the trader #{user.name}.
To complete the transaction, you need to transfer #{item.price} Bitcoins to #{user.name}'s wallet (#{user.wallet}).")
      self.send_mail("trading.mail@web.de", to, "Payment information #{item.name}", body)
    end

    def self.reset_pw(to, contents)
      self.send_mail("trading.mail@web.de", to, "Your password has been reset", contents)
    end

    def self.new_winner(to, auction)
      self.send_mail("trading.mail@web.de", to, "Higher bid", "Your bid on auction for #{auction.item.name} has been outbid.")
    end

    def self.bid_over(to, auction)
      self.send_mail("trading.mail@web.de", to, "Auction won!", "Congratulations, you won the auction for #{auction.item.name}!")
    end

    def self.send_personal_message(sender, recipient, subject, content, site_url)
      body = "You have a new message from <a href=\"http://#{site_url}/users/#{sender.id}\">#{sender.name}</a>:<hr />#{escape_html(content)}<hr /><br />"
      Mailer.send_mail(sender.e_mail, recipient.e_mail, subject, body)  
    end

    def self.send_mail(sender, receiver, subject, content)
      require 'rubygems'
      require 'tlsmail'
      require 'time'

      from = 'trading.mail@web.de'
      to = receiver
      pw = 'trade1234'
      
      content = <<EOF
From: #{sender}
To: #{receiver}
Subject: #{subject}
Date: #{Time.now.rfc2822}
Content-Type: text/html

#{content}

Regards,
The Trading System
EOF

puts content

      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start('smtp.web.de', 587, 'web.de', from, pw, :login) do |smtp|
        smtp.send_message(content, from, receiver)
      end     
    end
  end
end
