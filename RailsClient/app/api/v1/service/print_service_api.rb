module V1
  module Service
    class PrintServiceAPI<ServiceBase
      namespace 'printer'
      guard_all!

      get :data do
        printer=Printer::Client.new(params[:code])
        printer.gen_data
      end
    end
  end
end