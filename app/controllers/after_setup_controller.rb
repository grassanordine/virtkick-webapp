class AfterSetupController < ApplicationController
  include AfterSetupOnly
  include DemoSessionLimiter
end
