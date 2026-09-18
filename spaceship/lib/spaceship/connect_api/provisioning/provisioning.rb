require 'spaceship/connect_api/provisioning/client'

module Spaceship
  class ConnectAPI
    module Provisioning
      module API
        module Version
          V1 = "v1"
        end

        def provisioning_request_client=(provisioning_request_client)
          @provisioning_request_client = provisioning_request_client
        end

        def provisioning_request_client
          return @provisioning_request_client if @provisioning_request_client
          raise TypeError, "You need to instantiate this module with provisioning_request_client"
        end

        #
        # bundleIds
        #

        def get_bundle_ids(filter: {}, includes: nil, fields: nil, limit: nil, sort: nil)
          params = provisioning_request_client.build_params(filter: filter, includes: includes, fields: fields, limit: limit, sort: sort)
          provisioning_request_client.get("#{Version::V1}/bundleIds", params)
        end

        def get_bundle_id(bundle_id_id: {}, includes: nil)
          params = provisioning_request_client.build_params(filter: nil, includes: includes, limit: nil, sort: nil)
          provisioning_request_client.get("#{Version::V1}/bundleIds/#{bundle_id_id}", params)
        end

        def post_bundle_id(name:, platform: nil, identifier:, seed_id: nil, bundle_type: nil, capabilities: nil)
          attributes = {
            name: name,
            identifier: identifier,
            platform: platform,
            seedId: seed_id,
            bundleType: bundle_type
          }.compact

          body = {
            data: {
              attributes: attributes,
              type: "bundleIds"
            }
          }

          capability_data = Array(capabilities).compact
          if capability_data.any?
            body[:data][:relationships] = {
              bundleIdCapabilities: {
                data: capability_data
              }
            }
          end

          if bundle_type
            client = provisioning_request_client
            unless client.respond_to?(:web_session?) && client.web_session?
              raise "Creating App Clip bundle IDs requires an Apple ID / Developer Portal session (not an App Store Connect API key)"
            end
          end

          # Same host as @expo/apple-utils provisioningClient (services-account/v1)
          provisioning_request_client.post("#{Version::V1}/bundleIds", body)
        end

        #
        # bundleIdCapability
        #

        def get_bundle_id_capabilities(bundle_id_id:, includes: nil, limit: nil, sort: nil)
          params = provisioning_request_client.build_params(filter: nil, includes: includes, limit: limit, sort: sort)
          provisioning_request_client.get("#{Version::V1}/bundleIds/#{bundle_id_id}/bundleIdCapabilities", params)
        end

        def get_available_bundle_id_capabilities(bundle_id_id:)
          params = provisioning_request_client.build_params(filter: { bundleId: bundle_id_id })
          provisioning_request_client.get("#{Version::V1}/capabilities", params)
        end

        def post_bundle_id_capability(bundle_id_id:, capability_type:, settings: [])
          body = {
            data: {
              attributes: {
                capabilityType: capability_type,
                settings: settings
              },
              type: "bundleIdCapabilities",
              relationships: {
                bundleId: {
                  data: {
                    type: "bundleIds",
                    id: bundle_id_id
                  }
                }
              }
            }
          }
          provisioning_request_client.post("#{Version::V1}/bundleIdCapabilities", body)
        end

        def patch_bundle_id_capability(bundle_id_id:, seed_id:, enabled: false, capability_type:, settings: [], parent_bundle_id_id: nil, capability_id: nil, existing_capabilities: nil)
          capability_entry = {
            type: "bundleIdCapabilities",
            attributes: {
              enabled: enabled,
              settings: settings
            },
            relationships: {
              capability: {
                data: {
                  type: "capabilities",
                  id: capability_type
                }
              }
            }
          }
          capability_entry[:id] = capability_id if capability_id

          if parent_bundle_id_id
            capability_entry[:relationships][:parentBundleId] = {
              data: {
                type: "bundleIds",
                id: parent_bundle_id_id
              }
            }
          end

          capability_data = []
          Array(existing_capabilities).each do |existing|
            next if existing.nil?
            next if existing.is_type?(capability_type)

            capability_data << {
              type: "bundleIdCapabilities",
              id: existing.id,
              attributes: {
                enabled: true,
                settings: existing.settings || []
              },
              relationships: {
                capability: {
                  data: {
                    type: "capabilities",
                    id: existing.capability_type || existing.id.split('_').last
                  }
                }
              }
            }
          end
          capability_data << capability_entry

          body = {
            data: {
              type: "bundleIds",
              id: bundle_id_id,
              attributes: {
                permissions: {
                  edit: true,
                  delete: true
                },
                seedId: seed_id,
                teamId: provisioning_request_client.team_id
              }.compact,
              relationships: {
                bundleIdCapabilities: {
                  data: capability_data
                }
              }
            }
          }

          provisioning_request_client.patch("#{Version::V1}/bundleIds/#{bundle_id_id}", body)
        end

        def delete_bundle_id_capability(bundle_id_capability_id:)
          provisioning_request_client.delete("#{Version::V1}/bundleIdCapabilities/#{bundle_id_capability_id}")
        end

        #
        # certificates
        #

        def get_certificates(profile_id: nil, filter: {}, includes: nil, fields: nil, limit: nil, sort: nil)
          params = provisioning_request_client.build_params(filter: filter, includes: includes, fields: fields, limit: limit, sort: sort)
          if profile_id.nil?
            provisioning_request_client.get("#{Version::V1}/certificates", params)
          else
            provisioning_request_client.get("#{Version::V1}/profiles/#{profile_id}/certificates", params)
          end
        end

        def get_certificate(certificate_id: nil, includes: nil)
          params = provisioning_request_client.build_params(filter: nil, includes: includes, limit: nil, sort: nil)
          provisioning_request_client.get("#{Version::V1}/certificates/#{certificate_id}", params)
        end

        def post_certificate(attributes: {})
          body = {
            data: {
              attributes: attributes,
              type: "certificates"
            }
          }

          provisioning_request_client.post("#{Version::V1}/certificates", body)
        end

        def delete_certificate(certificate_id: nil)
          raise "Certificate id is nil" if certificate_id.nil?

          provisioning_request_client.delete("#{Version::V1}/certificates/#{certificate_id}")
        end

        #
        # devices
        #

        def get_devices(profile_id: nil, filter: {}, includes: nil, fields: nil, limit: nil, sort: nil)
          params = provisioning_request_client.build_params(filter: filter, includes: includes, fields: fields, limit: limit, sort: sort)
          if profile_id.nil?
            provisioning_request_client.get("#{Version::V1}/devices", params)
          else
            provisioning_request_client.get("#{Version::V1}/profiles/#{profile_id}/devices", params)
          end
        end

        def post_device(name: nil, platform: nil, udid: nil)
          attributes = {
            name: name,
            platform: platform,
            udid: udid
          }

          body = {
            data: {
              attributes: attributes,
              type: "devices"
            }
          }

          provisioning_request_client.post("#{Version::V1}/devices", body)
        end

        def patch_device(id: nil, status: nil, new_name: nil)
          raise "Device id is nil" if id.nil?

          attributes = {
            name: new_name,
            status: status
          }

          body = {
            data: {
              attributes: attributes,
              id: id,
              type: "devices"
            }
          }

          provisioning_request_client.patch("#{Version::V1}/devices/#{id}", body)
        end

        #
        # profiles
        #

        def get_profiles(filter: {}, includes: nil, fields: nil, limit: nil, sort: nil)
          params = provisioning_request_client.build_params(filter: filter, includes: includes, fields: fields, limit: limit, sort: sort)
          provisioning_request_client.get("#{Version::V1}/profiles", params)
        end

        def post_profiles(bundle_id_id: nil, certificates: nil, devices: nil, attributes: {})
          body = {
            data: {
              attributes: attributes,
              type: "profiles",
              relationships: {
                bundleId: {
                  data: {
                    type: "bundleIds",
                    id: bundle_id_id
                  }
                },
                certificates: {
                  data: certificates.map do |certificate|
                    {
                      type: "certificates",
                      id: certificate
                    }
                  end
                },
                devices: {
                  data: (devices || []).map do |device|
                    {
                      type: "devices",
                      id: device
                    }
                  end
                }
              }
            }
          }

          provisioning_request_client.post("#{Version::V1}/profiles", body)
        end

        def get_profile_bundle_id(profile_id: nil)
          raise "Profile id is nil" if profile_id.nil?

          provisioning_request_client.get("#{Version::V1}/profiles/#{profile_id}/bundleId")
        end

        def delete_profile(profile_id: nil)
          raise "Profile id is nil" if profile_id.nil?

          provisioning_request_client.delete("#{Version::V1}/profiles/#{profile_id}")
        end
      end
    end
  end
end
