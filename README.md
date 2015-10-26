# api-blueprint

Semi-automatic solution for creating Rails app's API documentation. Here's how it works:

1. You start with method list generated from RSpec request specs. For each method, you get a list of parameters and examples.
2. Then, you can extend it in whatever way you need using Markdown syntax. You can organize documentation files into partials.
3. Upon any API change, like serializer change that changes responses, you can update automatically generated parts of docs.
4. Once done, you can compile your documentation into single, nicely styled HTML file. You can also auto-deploy it via SSH.

## Installation

Add to `Gemfile`:

```ruby
gem 'api_blueprint'
```

Then run:

```
bundle install
```

Add the following inside `RSpec.configure` block in `spec/spec_helper.rb`:

```ruby
config.include ApiBlueprint::Collect::SpecHook
```

And the following to `app/controllers/application_controller.rb`:

```ruby
include Blueprint::Collect::ControllerHook
```

## Usage

**api-blueprint** allows to run RSpec request suite in order to auto-generate API method information. In order to do that you should invoke:

```
rake blueprint:collect
```

By default, all specs inside `spec/requests` are run. You can configure that by creating a [Blueprintfile](#configuration) configuration.

## Configuration

Configuration for **api-blueprint** lives in `Blueprintfile` inside application directory. It looks like this:

```yaml
api:
  spec: "spec/requests/api/v2"
  blueprint: "doc/api.md"
  html: "doc/api.html"
  deploy: "user@server.com:/home/app/public/api.html"
  naming:
    sessions:
      create: "Sign In"
```

Here's what specific options stand for:

Option | Description
-------|------------
`spec` | Rspec spec suite directory
`blueprint` | Main documentation file (Markdown)
`html` | Target HTML file created after compilation
`deploy` | SSH address used for documentation deployment
`naming` | Dictionary of custom API method names