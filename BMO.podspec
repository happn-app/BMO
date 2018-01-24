Pod::Spec.new do |spec|
	spec.name = "BMO"
	spec.version = "0.9.0"
	spec.summary = "Linking any local database (CoreData, Realm, etc.) to any API (REST, SOAP, etc.)"
	spec.homepage = "https://www.happn.com/"
	spec.license = {type: 'TBD', file: 'License.txt'}
	spec.authors = {"François Lamboley" => 'francois.lamboley@happn.com'}
	spec.social_media_url = "https://twitter.com/happn_tech"

	spec.requires_arc = true
	spec.source = {git: "git@github.com:happn-app/BMO.git", tag: spec.version}
	spec.source_files = "Sources/BMO/*.swift"

	spec.ios.deployment_target = '8.0'
	spec.osx.deployment_target = '10.10'
	spec.tvos.deployment_target = '9.0'
	spec.watchos.deployment_target = '2.0'
end
