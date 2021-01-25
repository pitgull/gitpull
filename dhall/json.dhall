let core = ./core.dhall

let TextMatcher = core.TextMatcher

let Matcher = core.Matcher

let Action = core.Action

let Rule = core.Rule

let ProjectConfig = core.ProjectConfig

let List/map =
      https://prelude.dhall-lang.org/v16.0.0/List/map sha256:dd845ffb4568d40327f2a817eb42d1c6138b929ca758d50bc33112ef3c885680

let JSON =
      https://prelude.dhall-lang.org/v16.0.0/JSON/package.dhall sha256:1b02c5ff4710f90ee3f8dc1a2565f1b52b45e5317e2df4775307e2ba0cadcf21

let listOf =
      λ(label : Text) →
      λ(values : List JSON.Type) →
        JSON.object
          (toMap { kind = JSON.string label, values = JSON.array values })

let toJsonFolds =
        { TextMatcher =
            λ(tm : TextMatcher) →
              tm
                JSON.Type
                { Equals =
                    λ(args : { value : Text }) →
                      JSON.object
                        ( toMap
                            { kind = JSON.string "Equals"
                            , value = JSON.string args.value
                            }
                        )
                , Matches =
                    λ(args : { regex : Text }) →
                      JSON.object
                        ( toMap
                            { kind = JSON.string "Matches"
                            , regex = JSON.string args.regex
                            }
                        )
                }
        , Matcher =
            λ(textMatcherToJson : TextMatcher → JSON.Type) →
            λ(matcher : Matcher) →
              matcher
                JSON.Type
                { Author =
                    λ(args : { email : TextMatcher }) →
                      JSON.object
                        ( toMap
                            { kind = JSON.string "Author"
                            , email = textMatcherToJson args.email
                            }
                        )
                , Description =
                    λ(args : { text : TextMatcher }) →
                      JSON.object
                        ( toMap
                            { kind = JSON.string "Description"
                            , text = textMatcherToJson args.text
                            }
                        )
                , PipelineStatus =
                    λ(args : { status : Text }) →
                      JSON.object
                        ( toMap
                            { kind = JSON.string "PipelineStatus"
                            , status = JSON.string args.status
                            }
                        )
                , Many = listOf "Many"
                , OneOf = listOf "OneOf"
                }
        , Action =
            λ(action : Action) →
              action JSON.Type { Merge = JSON.string "Merge" }
        }
      : { TextMatcher : TextMatcher → JSON.Type
        , Matcher : (TextMatcher → JSON.Type) → Matcher → JSON.Type
        , Action : Action → JSON.Type
        }

let projectToJson
    : ProjectConfig → JSON.Type
    = λ(config : ProjectConfig) →
        let matcherToJson = toJsonFolds.Matcher toJsonFolds.TextMatcher

        let ruleToJson
            : Rule → JSON.Type
            = λ(rule : Rule) →
                JSON.object
                  ( toMap
                      { name = JSON.string rule.name
                      , matcher = matcherToJson rule.matcher
                      , action = toJsonFolds.Action rule.action
                      }
                  )

        in  JSON.object
              ( toMap
                  { rules =
                      JSON.array
                        (List/map Rule JSON.Type ruleToJson config.rules)
                  }
              )

in  projectToJson
