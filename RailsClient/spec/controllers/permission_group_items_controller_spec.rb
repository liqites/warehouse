require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe PermissionGroupItemsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # PermissionGroupItem. As you add validations to PermissionGroupItem, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PermissionGroupItemsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "assigns all permission_group_items as @permission_group_items" do
      permission_group_item = PermissionGroupItem.create! valid_attributes
      get :index, {}, valid_session
      expect(assigns(:permission_group_items)).to eq([permission_group_item])
    end
  end

  describe "GET #show" do
    it "assigns the requested permission_group_item as @permission_group_item" do
      permission_group_item = PermissionGroupItem.create! valid_attributes
      get :show, {:id => permission_group_item.to_param}, valid_session
      expect(assigns(:permission_group_item)).to eq(permission_group_item)
    end
  end

  describe "GET #new" do
    it "assigns a new permission_group_item as @permission_group_item" do
      get :new, {}, valid_session
      expect(assigns(:permission_group_item)).to be_a_new(PermissionGroupItem)
    end
  end

  describe "GET #edit" do
    it "assigns the requested permission_group_item as @permission_group_item" do
      permission_group_item = PermissionGroupItem.create! valid_attributes
      get :edit, {:id => permission_group_item.to_param}, valid_session
      expect(assigns(:permission_group_item)).to eq(permission_group_item)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new PermissionGroupItem" do
        expect {
          post :create, {:permission_group_item => valid_attributes}, valid_session
        }.to change(PermissionGroupItem, :count).by(1)
      end

      it "assigns a newly created permission_group_item as @permission_group_item" do
        post :create, {:permission_group_item => valid_attributes}, valid_session
        expect(assigns(:permission_group_item)).to be_a(PermissionGroupItem)
        expect(assigns(:permission_group_item)).to be_persisted
      end

      it "redirects to the created permission_group_item" do
        post :create, {:permission_group_item => valid_attributes}, valid_session
        expect(response).to redirect_to(PermissionGroupItem.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved permission_group_item as @permission_group_item" do
        post :create, {:permission_group_item => invalid_attributes}, valid_session
        expect(assigns(:permission_group_item)).to be_a_new(PermissionGroupItem)
      end

      it "re-renders the 'new' template" do
        post :create, {:permission_group_item => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested permission_group_item" do
        permission_group_item = PermissionGroupItem.create! valid_attributes
        put :update, {:id => permission_group_item.to_param, :permission_group_item => new_attributes}, valid_session
        permission_group_item.reload
        skip("Add assertions for updated state")
      end

      it "assigns the requested permission_group_item as @permission_group_item" do
        permission_group_item = PermissionGroupItem.create! valid_attributes
        put :update, {:id => permission_group_item.to_param, :permission_group_item => valid_attributes}, valid_session
        expect(assigns(:permission_group_item)).to eq(permission_group_item)
      end

      it "redirects to the permission_group_item" do
        permission_group_item = PermissionGroupItem.create! valid_attributes
        put :update, {:id => permission_group_item.to_param, :permission_group_item => valid_attributes}, valid_session
        expect(response).to redirect_to(permission_group_item)
      end
    end

    context "with invalid params" do
      it "assigns the permission_group_item as @permission_group_item" do
        permission_group_item = PermissionGroupItem.create! valid_attributes
        put :update, {:id => permission_group_item.to_param, :permission_group_item => invalid_attributes}, valid_session
        expect(assigns(:permission_group_item)).to eq(permission_group_item)
      end

      it "re-renders the 'edit' template" do
        permission_group_item = PermissionGroupItem.create! valid_attributes
        put :update, {:id => permission_group_item.to_param, :permission_group_item => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested permission_group_item" do
      permission_group_item = PermissionGroupItem.create! valid_attributes
      expect {
        delete :destroy, {:id => permission_group_item.to_param}, valid_session
      }.to change(PermissionGroupItem, :count).by(-1)
    end

    it "redirects to the permission_group_items list" do
      permission_group_item = PermissionGroupItem.create! valid_attributes
      delete :destroy, {:id => permission_group_item.to_param}, valid_session
      expect(response).to redirect_to(permission_group_items_url)
    end
  end

end