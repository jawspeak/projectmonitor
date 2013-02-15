// Generated by CoffeeScript 1.4.0
(function() {

  describe("ProjectMonitor.Views.HomeView", function() {
    beforeEach(function() {
      var projects;
      projects = new ProjectMonitor.Collections.Projects([BackboneFactory.create('aggregate_project'), BackboneFactory.create('project')]);
      return this.view = new ProjectMonitor.Views.HomeView({
        collection: projects
      });
    });
    it("should render two tile", function() {
      return expect(this.view.render().$el.find("article").length).toEqual(2);
    });
    it("should render aggregate tile", function() {
      return expect(this.view.render().$el).toContain("li.aggregate_project");
    });
    it("should render standalong tile", function() {
      return expect(this.view.render().$el).toContain("li.project");
    });
    return it("should render only the latest ten builds", function() {
      return expect(this.view.render().$el.find('.statuses li').size()).toEqual(10);
    });
  });

}).call(this);