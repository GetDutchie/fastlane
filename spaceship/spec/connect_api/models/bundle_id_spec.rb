describe Spaceship::ConnectAPI::BundleId do
  let(:mock_portal_client) { double('portal_client') }
  let(:username) { 'spaceship@krausefx.com' }
  let(:password) { 'so_secret' }

  before do
    allow(mock_portal_client).to receive(:team_id).and_return("123")
    allow(mock_portal_client).to receive(:select_team)
    allow(mock_portal_client).to receive(:csrf_tokens)
    allow(Spaceship::PortalClient).to receive(:login).and_return(mock_portal_client)
    Spaceship::ConnectAPI.login(username, password, use_portal: true, use_tunes: false)
  end

  describe '#client' do
    it '#get_bundle_ids' do
      response = Spaceship::ConnectAPI.get_bundle_ids
      expect(response).to be_an_instance_of(Spaceship::ConnectAPI::Response)

      expect(response.count).to eq(2)
      response.each do |model|
        expect(model).to be_an_instance_of(Spaceship::ConnectAPI::BundleId)
      end

      model = response.first
      expect(model.identifier).to eq("com.joshholtz.FastlaneApp")
      expect(model.name).to eq("Fastlane App")
      expect(model.seedId).to eq("972KS36P2U")
      expect(model.platform).to eq("IOS")
    end
  end

  describe '.create' do
    it 'creates a standard bundle ID' do
      mock_response = double('response')
      mock_bundle_id = double('bundle_id')
      expect(Spaceship::ConnectAPI).to receive(:post_bundle_id).with(
        name: "App",
        platform: "IOS",
        identifier: "com.example.app",
        seed_id: nil,
        bundle_type: nil,
        capabilities: nil
      ).and_return(mock_response)
      expect(mock_response).to receive(:to_models).and_return([mock_bundle_id])

      result = Spaceship::ConnectAPI::BundleId.create(
        name: "App",
        platform: "IOS",
        identifier: "com.example.app"
      )
      expect(result).to eq(mock_bundle_id)
    end

    it 'creates an App Clip with ON_DEMAND + parent and ASSOCIATED_DOMAINS' do
      mock_response = double('response')
      created = double('bundle_id', id: "CLIPID", bundle_type: "onDemandInstallCapable")

      expect(Spaceship::ConnectAPI).to receive(:post_bundle_id) do |args|
        expect(args[:name]).to eq("App Clip")
        expect(args[:platform]).to eq("IOS")
        expect(args[:identifier]).to eq("com.dutchie.retailerSample.Clip")
        expect(args[:seed_id]).to be_nil
        expect(args[:bundle_type]).to eq("onDemandInstallCapable")
        caps = args[:capabilities]
        expect(caps.length).to eq(2)
        expect(caps[0][:relationships][:capability][:data][:id]).to eq("ON_DEMAND_INSTALL_CAPABLE")
        expect(caps[0][:relationships][:parentBundleId][:data][:id]).to eq("54S3W6FM53")
        expect(caps[1][:relationships][:capability][:data][:id]).to eq("ASSOCIATED_DOMAINS")
        mock_response
      end
      expect(mock_response).to receive(:to_models).and_return([created])

      result = Spaceship::ConnectAPI::BundleId.create(
        name: "App Clip",
        identifier: "com.dutchie.retailerSample.Clip",
        parent_bundle_id_id: "54S3W6FM53"
      )
      expect(result).to eq(created)
    end
  end
end
