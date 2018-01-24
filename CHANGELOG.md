**Version 0.5.1** - *2018-01-24*

- Fixed and refactored dirty tracking


**Version 0.5.0** - *2018-01-24*

- Speed optimizations
- Support for binary type


**Version 0.4.5** - *2018-01-23*

- Fixed memory bug with Mongocore.sort option
- Removed unused option
- Optimized cursor query


**Version 0.4.4** - *2018-01-19*

- Fixed dirty tracking clearing after save


**Version 0.4.3** - *2018-01-19*

- Reset model properly when doing a reload
- Removed update filter, both save and update uses the :save filter


**Version 0.4.1** - *2018-01-10*

- Automatically convert to Time for date if it's a Date or String


**Version 0.4.0** - *2017-12-01*

- Added each_with_index, each_with_object and map
- Added id = method
- Refactored cursor, faster finds
- Added paginate to model class methods


**Version 0.3.2** - *2017-11-25*

- Alias for insert is create


**Version 0.3.1** - *2017-11-25*

- Fixed bug where error didn't get reset on validation
- Can set association = nil
- Added default sort option
- Renamed a few internal variables


**Version 0.3.0** - *2017-10-30*

- Removed support for dependent destroy


**Version 0.1.0** - *2017-01-06*

- Fixed gemspec issues


**Version 0.1.0** - *2017-01-05*

- Automatic saving of created_at and updated_at keys if they exist
- All before and after filters working
- Tagged keys working
- Can do m.reload instead of m = m.reload
