defmodule PROJECT4 do
  def main(args) do
      [option, users] = args
      {no_users, _} = Integer.parse(users)
      {option, _} = Integer.parse(option)
      case option do
          0 ->
            Server.start_link(no_users)
          1 ->
            UserManager.start_link(no_users)
      end
  end
end
