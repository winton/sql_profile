##SqlProfile

Record EXPLAIN data for SQL queries in a running Rails 2.x app.

###Install

    gem install sql_profile

###Around Filter

    around_filter :sql_profile

    def sql_profile(&block)
      if params[:sql_profile]
        SqlProfile.around_filter(self, params[:sql_profile], &block)
      else
        yield
      end
    end

Now activate recording of EXPLAIN data by adding the `sql_profile` parameter:

    /my_page?sql_profile=my_segment

###Results

SqlProfile [writes EXPLAIN data to redis](https://github.com/winton/sql_profile/blob/07f89c0ac44b39576a6734aab3c7dc6564b10dee/lib/sql_profile.rb#L35-38) by git version, path, and segment.

This allows you to potentially compare EXPLAINs across multiple versions of your code.

### Contribute

[Create an issue](https://github.com/winton/sql_profile/issues/new) to discuss template changes.

Pull requests for template changes and new branches are even better.

### Stay up to date

[Star this project](https://github.com/winton/sql_profile#) on Github.

[Follow Winton Welsh](http://twitter.com/intent/user?screen_name=wintonius) on Twitter.
