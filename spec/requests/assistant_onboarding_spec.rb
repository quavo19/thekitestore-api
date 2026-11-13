require 'rails_helper'
RSpec.describe 'Assistant onboarding', type: :request do
  include ActiveJob::TestHelper
  let(:headers) { {'Authorization'=>'Bearer '+('x'*40), 'X-Assistant-Shop'=>'thekitestore'} }
  let(:context) { {'shop'=>'thekitestore','binding'=>'phone-a','channel'=>'whatsapp','actor'=>'sender','conversation'=>'chat'} }
  around do |example|
    values={'ASSISTANT_API_ENABLED'=>'true','ASSISTANT_IDENTITY_ENABLED'=>'true','ASSISTANT_SERVICE_TOKEN'=>'x'*40,'ASSISTANT_SHOP_ID'=>'thekitestore'}
    previous=values.keys.to_h { |k| [k,ENV[k]] }; values.each { |k,v| ENV[k]=v }
    begin; example.run; ensure; previous.each { |k,v| v.nil? ? ENV.delete(k) : ENV[k]=v }; end
  end
  def authenticate(action, email, password='password123', extra={})
    post '/api/v1/assistant/onboarding/authenticate',headers:headers,as: :json,
      params:{intent:action,credentials:{email:email,password:password,first_name:'New',last_name:'Customer'}.merge(extra),context:context}
    JSON.parse(response.body)['ticket']
  end
  def verify(ticket, code, ctx=context)
    post '/api/v1/assistant/onboarding/verify',headers:headers,as: :json,params:{ticket:ticket,code:code,context:ctx}
  end
  def code_for(user)
    message=ActionMailer::Base.deliveries.reverse.find { |m| m.to.include?(user.email) && m.subject=='Verify your shop account link' }
    message.body.decoded[/\b[0-9]{6}\b/]
  end
  it 'registers customers, verifies mail ownership, issues a single-use bound exchange' do
    Role.find_or_create_by!(name:'CUSTOMER')
    ticket=nil
    perform_enqueued_jobs(only:AssistantVerificationDeliveryJob) { ticket=authenticate('signup','new-assistant@example.test') }
    expect(response).to have_http_status(:ok)
    user=User.find_by!(email:'new-assistant@example.test')
    expect(user.role.name).to eq('CUSTOMER'); expect(user.assistant_email_verified_at).to be_nil
    verify(ticket,'000000',context.merge('shop'=>'other')); expect(response).to have_http_status(:not_found)
    verify(ticket,code_for(user)); expect(response).to have_http_status(:ok)
    code=JSON.parse(response.body)['code']; expect(user.reload.assistant_email_verified_at).not_to be_nil
    post '/api/v1/assistant/delegations/exchange',headers:headers,as: :json,params:{code:code,context:context}
    expect(response).to have_http_status(:ok)
    verify(ticket,code_for(user)); expect(response).to have_http_status(:not_found)
  end
  it 'uses sign-in for existing customers and bounds failed code attempts' do
    user=create(:user)
    ticket=nil
    perform_enqueued_jobs(only:AssistantVerificationDeliveryJob) { ticket=authenticate('signin',user.email) }
    expect(response).to have_http_status(:ok)
    5.times { verify(ticket,'wrong'); expect(response).to have_http_status(:not_found) }
    expect(AssistantChallenge.find_by!(ticket_digest:Digest::SHA256.hexdigest(ticket)).attempts).to eq(5)
    verify(ticket,code_for(user)); expect(response).to have_http_status(:not_found)
  end
  it 'returns opaque tickets for duplicate accounts, bad passwords and privileged roles' do
    user=create(:user)
    before=User.count
    %w[signup signin].each do |action|
      ticket=authenticate(action,user.email,'wrong-password'); expect(response).to have_http_status(:ok)
      verify(ticket,'123456'); expect(response).to have_http_status(:not_found)
    end
    expect(User.count).to eq(before)
    user.update!(role:Role.find_or_create_by!(name:'ADMIN'))
    ticket=authenticate('signin',user.email); expect(response).to have_http_status(:ok)
    verify(ticket,'123456'); expect(response).to have_http_status(:not_found)
    authenticate('signup','injection@example.test','password123',{'role_id'=>user.role_id})
    expect(response).to have_http_status(:unprocessable_entity)
  end
  it 'assigns CUSTOMER on public registration despite injected role' do
    Role.find_or_create_by!(name:'CUSTOMER'); admin=Role.find_or_create_by!(name:'ADMIN')
    post '/api/v1/auth/signup',as: :json,params:{user:{email:'public-assistant@example.test',password:'password123',password_confirmation:'password123',first_name:'Public',last_name:'Customer',role_id:admin.id}}
    expect(response).to have_http_status(:ok)
    expect(User.find_by!(email:'public-assistant@example.test').role.name).to eq('CUSTOMER')
  end
  it 'denies expired challenges, changed credentials, OTP accounts and disabled identity' do
    user=create(:user)
    ticket=nil
    perform_enqueued_jobs(only:AssistantVerificationDeliveryJob) { ticket=authenticate('signin',user.email) }
    code=code_for(user)
    user.update!(password:'a-new-password',password_confirmation:'a-new-password')
    verify(ticket,code); expect(response).to have_http_status(:not_found)
    ticket=nil
    perform_enqueued_jobs(only:AssistantVerificationDeliveryJob) { ticket=authenticate('signin',user.email,'a-new-password') }
    code=code_for(user)
    AssistantChallenge.find_by!(ticket_digest:Digest::SHA256.hexdigest(ticket)).update!(expires_at:1.second.ago)
    verify(ticket,code); expect(response).to have_http_status(:not_found)
    user.update!(otp_enabled:true,otp_secret:ROTP::Base32.random)
    ticket=authenticate('signin',user.email,'a-new-password')
    expect(AssistantChallenge.find_by!(ticket_digest:Digest::SHA256.hexdigest(ticket)).user_id).to be_nil
    ENV['ASSISTANT_IDENTITY_ENABLED']='false'
    authenticate('signin',user.email,'a-new-password'); expect(response).to have_http_status(:not_found)
  end

end
