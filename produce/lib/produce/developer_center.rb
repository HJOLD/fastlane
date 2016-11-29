require 'spaceship'
require 'babosa'

module Produce
  class DeveloperCenter
    def run
      login
      create_new_app
    end

    def create_new_app
      ENV["CREATED_NEW_APP_ID"] = Time.now.to_i.to_s

      if app_exists?
        UI.success "[DevCenter] App '#{Produce.config[:app_identifier]}' already exists, nothing to do on the Dev Center"
        ENV["CREATED_NEW_APP_ID"] = nil
        # Nothing to do here
      else
        app_name = Produce.config[:app_name]
        UI.message "Creating new app '#{app_name}' on the Apple Dev Center"

        allowed_keys = [:app_group, :apple_pay, :associated_domains, :data_protection, :game_center, :health_kit, :home_kit,
                        :wireless_accessory, :icloud, :in_app_purchase, :inter_app_audio, :passbook, :push_notification, :siri_kit, :vpn_configuration]

        Produce.config[:enabled_features].select { |key, value| allowed_keys.include? key }

        enabled_clean_options = {}
        Produce.config[:enabled_features].each do |k, v|
          if k == :data_protection
            case v
            when "complete"
              enabled_clean_options[Spaceship.app_service.data_protection.complete.service_id] = Spaceship.app_service.data_protection.complete.on
            when "unlessopen"
              enabled_clean_options[Spaceship.app_service.data_protection.unlessopen.service_id] = Spaceship.app_service.data_protection.unlessopen.on
            when "untilfirstauth"
              enabled_clean_options[Spaceship.app_service.data_protection.untilfirstauth.service_id] = Spaceship.app_service.data_protection.untilfirstauth.on
            end
          elsif k == :icloud
            case v
            when "legacy"
              enabled_clean_options[Spaceship.app_service.icloud.on.service_id] = Spaceship.app_service.icloud.on
              enabled_clean_options[Spaceship.app_service.cloud_kit.xcode5_compatible.service_id] = Spaceship.app_service.cloud_kit.xcode5_compatible
            when "cloudkit"
              enabled_clean_options[Spaceship.app_service.icloud.on.service_id] = Spaceship.app_service.icloud.on
              enabled_clean_options[Spaceship.app_service.cloud_kit.cloud_kit.service_id] = Spaceship.app_service.cloud_kit.cloud_kit
            end
          else
            if v == "on"
              enabled_clean_options[Spaceship.app_service.send(k.to_s).on.service_id] = Spaceship.app_service.send(k.to_s).on
            else
              enabled_clean_options[Spaceship.app_service.send(k.to_s).off.service_id] = Spaceship.app_service.send(k.to_s).off
            end
          end
        end
        app = Spaceship.app.create!(bundle_id: app_identifier,
                                         name: app_name,
                                         mac: Produce.config[:platform] == "osx",
                                         enabled_features: enabled_clean_options)

        if app.name != Produce.config[:app_name]
          UI.important("Your app name includes non-ASCII characters, which are not supported by the Apple Developer Portal.")
          UI.important("To fix this a unique (internal) name '#{app.name}' has been created for you. Your app's real name '#{Produce.config[:app_name]}'")
          UI.important("will still show up correctly on iTunes Connect and the App Store.")
        end

        UI.message "Created app #{app.app_id}"

        UI.crash!("Something went wrong when creating the new app - it's not listed in the apps list") unless app_exists?

        ENV["CREATED_NEW_APP_ID"] = Time.now.to_i.to_s

        UI.success "Finished creating new app '#{app_name}' on the Dev Center"
      end

      return true
    end

    def app_identifier
      Produce.config[:app_identifier].to_s
    end

    private

    def app_exists?
      Spaceship.app.find(app_identifier, mac: Produce.config[:platform] == "osx") != nil
    end

    def login
      Spaceship.login(Produce.config[:username], nil)
      Spaceship.select_team
    end
  end
end
