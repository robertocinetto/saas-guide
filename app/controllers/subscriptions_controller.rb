class SubscriptionsController < ApplicationController

  before_action :authenticate_user!

  def index
    @account  = Account.find_by_email current_user.email
  end

  def edit
    @account  = Account.find params[:id]
    @plans    = Plan.all
  end

  def new
    @plans = Plan.all
  end

  def create
    # Get the credit card details submitted by the form
    token           = params[:stripeToken]
    plan            = params[:plan][:stripe_id]
    email           = current_user.email
    current_account = Account.find_by_email current_user.email
    customer_id     = current_account.customer_id
    current_plan    = current_account.stripe_plan_id

    if customer_id.nil?
      #New customer -> Create a customer
      # Create a Customer
      @customer = Stripe::Customer.create(
        :source => token,
        :plan   => plan,
        :email  => email
      )
      subscriptions = @customer.subscriptions
      @subscribed_plan = subscriptions.data.find { |o| o.plan.id == plan }
    else
      #customer exits
      @customer = Stripe::Customer.retrieve customer_id
      @subscribed_plan = create_or_update_subscription( @customer, current_plan, plan )
    end


    
    #Get current period end - this is a unix timestamp
    current_period_end = @subscribed_plan.current_period_end
    #Convert to datetime
    active_until = Time.at( current_period_end ).to_datetime

    save_account_details( current_account, plan, @customer.id, active_until )

    redirect_to :root, notice: "Successfully subscribed to the plan"

  rescue => e
    redirect_to :back, flash: { error: e.message }
  end



  def cancel_subscription
    email           = current_user.email
    current_account = Account.find_by_email current_user.email
    customer_id     = current_account.customer_id
    current_plan    = current_account.stripe_plan_id

    if current_plan.blank?
      raise "No plan foudn to unsubscribe/cancel"
    end

    #fetch customer from stripe
    customer = Stripe::Customer.retrieve customer_id
    
    #fetch customer's subscriptions
    subscriptions = customer.subscriptions
    
    #find the subscription we want to cancele
    current_subscribed_plan = subscriptions.data.find { |o| o.plan.id == current_plan }
    
    if current_subscribed_plan.blank?
      raise "subscription not found!"
    end

    #delete it
    current_subscribed_plan.delete

    #update account model
    save_account_details( current_account, nil, customer_id, Time.at(0).to_datetime )

    @message = "Subscription cancelled successfully"

  rescue => e
    redirect_to "/subscriptions", flash: { error: e.message }
  end


  def update_card
    
  end

  def update_card_details
    #take the token given by stripe and set in on customer
    token           = params[:stripeToken]
    #get customer id
    current_account = Account.find_by_email current_user.email
    customer_id     = current_account.customer_id

    #get customer 
    customer = Stripe::Customer.retrieve customer_id
    customer.source = token
    customer.save

    redirect_to "/subscriptions", notice: "Card update successfully!"

    rescue => e
      redirect_to action: "update_card", flash: { notice: e.message } 
  end


  def save_account_details( account, plan, customer_id, active_until )
    #customer created with a valid subscription
    account.stripe_plan_id = plan
    account.customer_id    = customer_id
    account.active_until   = active_until
    account.save!
  end

  def create_or_update_subscription( customer, current_plan, new_plan )
    subscriptions = customer.subscriptions
    #get current subscription
    current_subscription = subscriptions.data.find { |o| o.plan.id == current_plan }

    if current_subscription.blank?
      #no current subscription
      #maybe the custuomer unsubscribed before or credit card declined
      subscriptions = customer.subscriptions.create( { plan: new_plan } )
    else
      #existing subscription found
      #must be an upgrade or a downgrade
      #so we update current subscription with new plan
      current_subscription.plan = new_plan
      subscriptions             = current_subscription.save
    end

    subscriptions
  end


end
